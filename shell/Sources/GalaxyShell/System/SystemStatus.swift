import Foundation
import IOKit.ps
import CoreWLAN
import CoreAudio
import AudioToolbox

/// Reads battery, Wi-Fi and volume for the Galaxy bar.
enum SystemStatus {
    struct Battery: Equatable {
        var percent: Int
        var charging: Bool
        var onPower: Bool
    }

    static func battery() -> Battery? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in list {
            guard let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  let current = desc[kIOPSCurrentCapacityKey] as? Int,
                  let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0
            else { continue }
            let charging = desc[kIOPSIsChargingKey] as? Bool ?? false
            let state = desc[kIOPSPowerSourceStateKey] as? String
            return Battery(percent: current * 100 / max,
                           charging: charging,
                           onPower: state == kIOPSACPowerValue)
        }
        return nil
    }

    static func wifiOn() -> Bool {
        CWWiFiClient.shared().interface()?.powerOn() ?? false
    }

    /// Output volume 0...1 of the current output device, or nil if unknown.
    static func outputVolume() -> Float? {
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                         &address, 0, nil, &size, &device) == noErr
        else { return nil }

        var volume = Float32(0)
        size = UInt32(MemoryLayout<Float32>.size)
        address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume) == noErr
        else { return nil }
        return volume
    }
}
