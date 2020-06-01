### TODOs

- [x] Add option to calculate and save Lean Mass
- [x] Complete Historical Sync Function
- [x] Update sync start date after sync completes
- [x] Add HealthKit.save functions to background group to monitor progress
- [x] Add UI to include/exclude non-aria records
- [x] Create FitbitAPIManager caller protocol and delegate
- [ ] Create HealthkitManager caller protocol and delegate
- [x] Convert to universal logging
- [x] Change all the API URL references to ariasync.test
- [x] Improve error handling
  - [x] Don't display success message when OAuth fails
  - [ ] API expired tokens
    - not sure if this is still a problem, should just work? Could test by resetting tokens on Fitbit's website
  - [ ] Auto prompt to reauthorize? need to avoid loop if user doesn't approve
    - also should just work with OAuth framework....
- [ ] set up notifications for changes to AriaSyncOptions  in AriaSyncViewController?

  
  
- [x] Add background fetch functionality
- [x] HealthKit access revoked or unavailable
  - [x] notify user
  - [x] disable sync button
- [ ] API rate limit handling
  - should display a useful error message, but hard to test for. Resets every hour
  - 
- [ ] slow/unavailable network
- [x] Create launch screen
- [x] Add app icon
  - [x] Add sync icon
- [ ] ~~Animate?~~ - tested animations; found to be unattractive


- [ ] Update to Swift 5/Xcode 11
  - [ ] update OAuth to v5
  - [ ] re-add OAuth using Swift Package Manager
