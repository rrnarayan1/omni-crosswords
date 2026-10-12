//
//  SpeechUtils.swift
//  crosswords
//
//  Created by Rohan Narayan on 10/12/26.
//  Copyright © 2026 Rohan Narayan. All rights reserved.
//

import AVFoundation
import SwiftUI

struct SpeechUtils {
    static func speakClue(synthesizer: AVSpeechSynthesizer, clue: String) {
        let utterance = AVSpeechUtterance(string: clue)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        synthesizer.speak(utterance)
    }
}
