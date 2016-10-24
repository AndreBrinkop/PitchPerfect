//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by André Brinkop on 22.10.16.
//  Copyright © 2016 André Brinkop. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var stopRecordingButton: UIButton!
    @IBOutlet weak var audioMeterConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioMeter: UIView!
    @IBOutlet weak var audioMeterView: UIView!
    
    var audioRecorder:AVAudioRecorder!
    var isRecording: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        stopRecordingButton.isEnabled = false
        audioMeter.isHidden = true
    }
    
    @IBAction func recordAudio(_ sender: AnyObject) {
        print("record button pressed")
        recordingLabel.text = "Recording in progress"
        stopRecordingButton.isEnabled = true
        recordButton.isEnabled = false
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURL(withPathComponents: pathArray)
        print(filePath)
        
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        
        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        
        audioRecorder.record()
        isRecording = true
        
        OperationQueue().addOperation({[weak self] in
            repeat {
                self?.audioRecorder.updateMeters()
                let averagePower = (self?.audioRecorder.averagePower(forChannel: 0))!
                self?.setAudioMeter(currentPower: averagePower)

                Thread.sleep(forTimeInterval: 0.025)
            }
                while (self?.isRecording)!
            })
    }

    @IBAction func stopRecording(_ sender: AnyObject) {
        print("stop recording button pressed")
        recordingLabel.text = "Tap to Record"
        stopRecordingButton.isEnabled = false
        recordButton.isEnabled = true
        audioMeter.isHidden = true
        
        audioRecorder.stop()
        isRecording = false
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully successful: Bool) {
        print("AVAudioRecorder finished saving recording")
        if successful {
            self.performSegue(withIdentifier: "stopRecording", sender: audioRecorder.url)
        } else {
            print("Saving of recording failed")
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "stopRecording" {
            let playSoundsVC = segue.destination as! PlaySoundsViewController
            let recordedAudioURL = sender as! NSURL
            playSoundsVC.recordedAudioURL = recordedAudioURL
        }
    }
    
    private func setAudioMeter(currentPower: Float) {
        let normalizedPower : Float! = getNormalizedMeterLevel(currentPower: currentPower)
        
        let viewHeight: CGFloat! = audioMeterView.frame.size.height
        let meterLevel = viewHeight * CGFloat(normalizedPower)
        
        audioMeter.isHidden = false
        DispatchQueue.main.async {
            self.audioMeterConstraint.constant = viewHeight - meterLevel
        }
    }
    
    private func getNormalizedMeterLevel(currentPower: Float) -> Float {
        var normalizedPower = currentPower + 60 // using 60 instead of 160 to remove noise
        normalizedPower = normalizedPower / 60
        
        if normalizedPower < 0 {
            normalizedPower = 0
        }
        if normalizedPower > 1 {
            normalizedPower = 1
        }
        
        return normalizedPower
    }
    
}

