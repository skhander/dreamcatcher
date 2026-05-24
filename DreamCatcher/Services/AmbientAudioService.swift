import Foundation
import AVFoundation
import AudioToolbox

@MainActor
final class AmbientAudioService: ObservableObject {
    static let shared = AmbientAudioService()

    @Published var isPlaying = false
    @Published var volume: Float = 0.15

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    private init() {}

    func startBedsideAmbience() {
        guard !isPlaying else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }

        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate

        var phase: Double = 0
        var lfoPhase: Double = 0
        var wowPhase: Double = 0

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let baseFreq1 = 110.0
            let baseFreq2 = 164.81
            let lfoRate = 0.08
            let wowRate = 0.03

            for frame in 0..<Int(frameCount) {
                lfoPhase += (2.0 * .pi * lfoRate) / sampleRate
                if lfoPhase > 2.0 * .pi { lfoPhase -= 2.0 * .pi }
                let lfo = 0.5 + 0.5 * sin(lfoPhase)

                wowPhase += (2.0 * .pi * wowRate) / sampleRate
                if wowPhase > 2.0 * .pi { wowPhase -= 2.0 * .pi }
                let wow = 1.0 + 0.012 * sin(wowPhase)

                phase += 1.0 / sampleRate
                let t = phase

                let wave1 = sin(2.0 * .pi * baseFreq1 * wow * t) * 0.3
                let wave2 = sin(2.0 * .pi * baseFreq2 * wow * t) * 0.2
                let phaser = sin(2.0 * .pi * 0.5 * t) * 0.04
                let noise = (Double.random(in: -1...1)) * 0.018
                let sample = Float((wave1 + wave2 + phaser + noise) * lfo * 0.08)

                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: format)
        mainMixer.outputVolume = volume

        do {
            try engine.start()
            self.engine = engine
            self.sourceNode = sourceNode
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
        sourceNode = nil
        isPlaying = false
    }

    func setVolume(_ newVolume: Float) {
        volume = newVolume
        engine?.mainMixerNode.outputVolume = newVolume
    }

    func playChime() {
        AudioServicesPlaySystemSound(1057)
    }
}
