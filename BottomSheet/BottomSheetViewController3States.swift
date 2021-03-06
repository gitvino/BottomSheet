//
//  BottomSheetViewController3States.swift
//  BottomSheet
//
//  Created by Vinoth on 4/1/20.
//  Copyright © 2020 Vinoth. All rights reserved.
//

import UIKit

class BottomSheetViewController3States: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    @IBOutlet var gripperView: UIView!
    @IBOutlet weak var destinationText: DesignableUITextField!
    @IBOutlet weak var destinationTable: UITableView!
    @IBOutlet weak var destinationTitleLabel: UILabel!
    
    enum State {
        case collapsed
        case halfscreen
        case fullscreen
    }
    
    enum PanDirection {
        case up
        case down
    }
    
    var delegate: BottomView?
    var currentState, nextState: State?
    var runningAnimations = [UIViewPropertyAnimator]()
    var visualEffectView: UIVisualEffectView!
    
    
    let cardHeight: CGFloat = UIScreen.main.bounds.height - 150
    let collapsedHeight = UIScreen.main.bounds.height - 150
    let halfScreenHeight = UIScreen.main.bounds.height / 2
    let fullscreenHeight:CGFloat = 150
    var animationPrgressWhenInterrupted:CGFloat = 0
   
    struct SampleData {
        var address1: String
        var address2: String
    }
    let sampleData = [
        SampleData(address1: "Apple Park", address2: "One Apple Park Way, Cupertino, CA 95014, USA"),
        SampleData(address1: "Tesla Headquarters", address2: "3500 Deer Creek Road, Palo Alto, CA 94304, USA"),
        SampleData(address1: "Google", address2: "1600 Amphitheatre PkwyMountain View, CA 94043, USA"),
        SampleData(address1: "Twitter", address2: "1355 Market Street Suite 900, San Francisco, USA"),
        SampleData(address1: "Facebook", address2: "1 Hackerway, Menlo Park, CA 94025, USA"),
    ]
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupText()
        setupBottomSheetView()
        currentState = .collapsed
        
        visualEffectView = UIVisualEffectView()

        let panGestureRecognizer =  UIPanGestureRecognizer(target: self, action: #selector(handleCardPan(recognizer:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
        self.delegate!.addUIVisualEffectsView(visualEffectView: visualEffectView)
        
        destinationTable.dataSource = self
        destinationTable.delegate = self
        destinationTable.register(UINib(nibName: "DestinationCell", bundle: nil), forCellReuseIdentifier: "DestinationCell")
        
        destinationText.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification , object:nil)
    }
    
    fileprivate func setupBottomSheetView() {
        // Gripper
        self.gripperView.layer.cornerRadius = 3
        self.view.layer.shadowRadius = 5
        self.view.layer.shadowColor = UIColor.gray.cgColor
        self.view.layer.shadowOpacity = 0.9
    }
    
    fileprivate func setupText() {
          destinationTitleLabel.text = NSLocalizedString("Where would you like to go?", comment: "Where would you like to go?")
          destinationText.placeholder = NSLocalizedString("Search for destination", comment: "Search for destination")
      }
      
    fileprivate func setNextState(panDirection panDirection: BottomSheetViewController3States.PanDirection) {
        
        switch currentState  {
        case .collapsed:
            switch panDirection {
            case .up:
                nextState = .halfscreen
            case .down:
                nextState = nil
                
            }
        case .halfscreen:
            switch panDirection {
            case .up:
                nextState = .fullscreen
            case .down:
                nextState = .collapsed
                
            }
        case .fullscreen:
            switch panDirection {
            case .up:
                nextState = nil
            case .down:
                nextState = .halfscreen
            }
        default:
            break
        }
    }
    
    @objc
    func handleCardPan(recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.view)
        let panDirection: PanDirection = (translation.y > 0) ? .down : .up
        setNextState(panDirection: panDirection)
        
        switch recognizer.state {
            
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            
            var fractionComplete = translation.y / cardHeight
            fractionComplete = (translation.y > 0) ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
            
        case .ended:
            continueInteractionTransition()
            
        default:
            break
        }
        
    }
    
    func startInteractiveTransition(state: State?, duration:TimeInterval) {
        
        if runningAnimations .isEmpty {
            animateTransitionsIfNeeded(state: nextState, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationPrgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat)  {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationPrgressWhenInterrupted
        }
    }
    func continueInteractionTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    func animateTransitionsIfNeeded(state: State?, duration: TimeInterval) {
        guard let state = state else {
            return
        }
        if runningAnimations .isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                
                switch state {
                    
                case .halfscreen:
                    self.view.frame.origin.y = self.halfScreenHeight
                    self.currentState = .halfscreen
                    self.destinationTable.isScrollEnabled = false
                    self.destinationText.resignFirstResponder()
                    
                case .fullscreen:
                    self.view.frame.origin.y = self.fullscreenHeight
                    self.currentState = .fullscreen
                    self.destinationTable.isScrollEnabled = true
                    
                    
                case .collapsed:
                    self.view.frame.origin.y = self.collapsedHeight
                    self.currentState = .collapsed
                    self.destinationTable.isScrollEnabled = false
                    self.destinationText.resignFirstResponder()
                    
                default:
                    break
                }
                
            }
            frameAnimator.addCompletion({ (_) in
                self.runningAnimations.removeAll()
            })
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .fullscreen, .halfscreen:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                    
                case .collapsed:
                    self.visualEffectView.effect = nil
                default:
                    break
                }
            }
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
               
                 switch state {
                 case .fullscreen:
                        self.view.layer.cornerRadius = 12
                 case .halfscreen:
                    self.view.layer.cornerRadius = 6
                 case .collapsed:
                    self.view.layer.cornerRadius = 0
            }
        }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
    }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell") as! DestinationCell
            cell.locationImage.image =  UIImage(systemName: "location")
            cell.title.text = sampleData[indexPath.row % 5].address1
            cell.subtitle.text  = sampleData[indexPath.row % 5].address2

        return cell
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if (currentState == State.collapsed) || (currentState == State.halfscreen) {
            nextState = .fullscreen
            startInteractiveTransition(state: nextState, duration: 0.9)
            continueInteractionTransition()
        }
       
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField .resignFirstResponder()
        return true;
    }

}
