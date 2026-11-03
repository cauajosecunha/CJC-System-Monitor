using System;
using System.IO.MemoryMappedFiles;
using System.Runtime.InteropServices;
using System.Threading;
using Microsoft.Win32;

public class Program {
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct HWiNFO_MEM_HEADER {
        public uint dwSignature;
        public uint dwVersion;
        public uint dwRevision;
        public long poll_time;
        public uint dwOffsetOfSensorSection;
        public uint dwSizeOfSensorElement;
        public uint dwNumSensorElements;
        public uint dwOffsetOfReadingSection;
        public uint dwSizeOfReadingElement;
        public uint dwNumReadingElements;
        public uint dwPollingPeriod;
    }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct HWiNFO_READING_ELEMENT {
        public uint tReading;
        public uint dwSensorIndex;
        public uint dwReadingID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string szLabelOrig;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string szLabelUser;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 16)]
        public string szUnit;
        public double Value;
        public double ValueMin;
        public double ValueMax;
        public double ValueAvg;
    }

    public static double? GetTempFromSharedMemory() {
        try {
            using (var mmf = MemoryMappedFile.OpenExisting(@"Global\HWiNFO_SENS_SM2")) {
                using (var mutex = Mutex.OpenExisting(@"Global\HWiNFO_SM2_MUTEX")) {
                    if (!mutex.WaitOne(300)) return null;
                    try {
                        using (var accessor = mmf.CreateViewAccessor(0, 0, MemoryMappedFileAccess.Read)) {
                            HWiNFO_MEM_HEADER header;
                            accessor.Read(0, out header);
                            if (header.dwSignature != 0x53695748) return null; // "HWiS"

                            long readingOffset = header.dwOffsetOfReadingSection;
                            int elemSize = (int)header.dwSizeOfReadingElement;
                            byte[] buffer = new byte[elemSize];

                            double? fallbackTemp = null;

                            for (int i = 0; i < header.dwNumReadingElements; i++) {
                                accessor.ReadArray(readingOffset + (i * elemSize), buffer, 0, elemSize);
                                GCHandle handle = GCHandle.Alloc(buffer, GCHandleType.Pinned);
                                try {
                                    HWiNFO_READING_ELEMENT elem = (HWiNFO_READING_ELEMENT)Marshal.PtrToStructure(handle.AddrOfPinnedObject(), typeof(HWiNFO_READING_ELEMENT));
                                    if (elem.tReading == 1 && elem.Value > 0) { // SENSOR_TYPE_TEMP
                                        string label = (elem.szLabelUser ?? elem.szLabelOrig ?? "").ToLowerInvariant();
                                        if (label.Contains("tctl/tdie") || label.Contains("tctl")) {
                                            return elem.Value;
                                        }
                                        if (label.Contains("tdie") || label.Contains("cpu die") || label.Contains("cpu package")) {
                                            fallbackTemp = elem.Value;
                                        } else if (fallbackTemp == null && (label.Contains("cpu") || label.Contains("core"))) {
                                            fallbackTemp = elem.Value;
                                        }
                                    }
                                } finally {
                                    handle.Free();
                                }
                            }
                            return fallbackTemp;
                        }
                    } finally {
                        mutex.ReleaseMutex();
                    }
                }
            }
        } catch {
            return null;
        }
    }

    public static double? GetTempFromRegistry() {
        try {
            using (var key = Registry.CurrentUser.OpenSubKey(@"Software\HWiNFO64\VSB")) {
                if (key == null) return null;
                double? fallback = null;
                for (int i = 0; i < 64; i++) {
                    object labelObj = key.GetValue("Label" + i);
                    if (labelObj == null) continue;
                    string label = labelObj.ToString().ToLowerInvariant();
                    object valRawObj = key.GetValue("ValueRaw" + i) ?? key.GetValue("Value" + i);
                    if (valRawObj == null) continue;

                    string valStr = valRawObj.ToString().Replace("°C", "").Replace("C", "").Trim();
                    double val;
                    if (double.TryParse(valStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out val) ||
                        double.TryParse(valStr, out val)) {
                        if (val > 0 && val < 130) {
                            if (label.Contains("tctl/tdie") || label.Contains("tctl")) return val;
                            if (label.Contains("tdie") || label.Contains("cpu die") || label.Contains("cpu package")) fallback = val;
                            else if (fallback == null && label.Contains("cpu")) fallback = val;
                        }
                    }
                }
                return fallback;
            }
        } catch {
            return null;
        }
    }

    public static double? GetTempFromWmi() {
        string[] namespaces = new string[] { @"root\LibreHardwareMonitor", @"root\OpenHardwareMonitor" };
        foreach (var ns in namespaces) {
            try {
                using (var searcher = new System.Management.ManagementObjectSearcher(ns, "SELECT Name, Value, SensorType FROM Sensor WHERE SensorType = 'Temperature'")) {
                    using (var collection = searcher.Get()) {
                        double? fallback = null;
                        foreach (System.Management.ManagementObject obj in collection) {
                            string name = (obj["Name"] ?? "").ToString().ToLowerInvariant();
                            object valObj = obj["Value"];
                            if (valObj == null) continue;
                            double val;
                            if (double.TryParse(valObj.ToString(), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out val)) {
                                if (val > 0 && val < 130) {
                                    if (name.Contains("tctl/tdie") || name.Contains("tctl") || name.Contains("package")) return val;
                                    if (name.Contains("cpu") || name.Contains("core")) fallback = val;
                                }
                            }
                        }
                        if (fallback.HasValue) return fallback.Value;
                    }
                }
            } catch {}
        }
        return null;
    }

    public static double? GetCpuTemp() {
        return GetTempFromSharedMemory() ?? GetTempFromRegistry() ?? GetTempFromWmi();
    }

    public static void Main(string[] args) {
        bool loop = args.Length > 0 && args[0] == "--loop";
        int interval = 2000;
        if (args.Length > 1) {
            int parsed;
            if (int.TryParse(args[1], out parsed) && parsed >= 500) {
                interval = parsed;
            }
        }

        if (loop) {
            while (true) {
                double? temp = GetCpuTemp();
                if (temp.HasValue) {
                    Console.WriteLine(string.Format(System.Globalization.CultureInfo.InvariantCulture, "TEMP:{0:F1}", temp.Value));
                } else {
                    Console.WriteLine("TEMP:NULL");
                }
                Thread.Sleep(interval);
            }
        } else {
            double? temp = GetCpuTemp();
            if (temp.HasValue) {
                Console.WriteLine(string.Format(System.Globalization.CultureInfo.InvariantCulture, "{0:F1}", temp.Value));
            } else {
                Console.WriteLine("NULL");
            }
        }
    }
}
