# AriaSync Readme

<img src="https://github.com/acahir/AriaSync/blob/master/Images/ariasync_screenshot.png" height="500" align="right" title="AriaSync">

### About

AriaSync is a single-purpose app to download data from the Aria scale stored in a user's fitbit account. It uses a Fitbit API call which avoids interpolated data between actual scale readings. 

If you are looking for a solution to get any other data from Fitbit into Apple's HealthKit, please try the excellent apps at http://syncsolver.com. 


### Deployment

Currently this app is not currently available on the Apple App Store.

You can download, built, and install the app onto your own devices. The biggest hurdle is configuring the Fitbit API, as the client ID and Secrets are not included in the source code (following best practices). You can register for your own IDs and codes through Fitbit's website, and all of the steps are outlined below. Note this is just an online, not a keystroke by keystroke guide.

**Note:** This app is currently developed with Swift 4, and has not been updated to compile with Swift 5.

1. Download Xcode from the macOS App Store
2. Download this project either via zip file or git. 
3. Open the AriaSync.xcodeproj file. 
4. Signup for developer access at [Fitbit](https://dev.fitbit.com/login)
5. Register an App with the following settings:
- Application Name: AriaSync or Make one up
- Description: Sync Aria information with Apple HealthKit
- Application Website: Your website (doesn't really have to work)
- Organization: You
- Organization Website: Same as Application Website
- Terms of Service URL: Same as Application Website
- Privacy Policy URL: Save as Application Website
- OAuth 2.0 Application Type: Client
- Callback URL: com.ariasync.ariasync://oauth/callback
Note: The callback URL must match the settings in the Xcode project settings. You can use your own web address, in reverse format, but you will need to change it in the source code as well. Also Fitbit always returns lowercase no matter what you define!!
Default Access Type: Read-Only

Note: I'm not commenting on how all the information you entered relates to the API terms set out by Fitbit. You read them before agreeing to them didn't you?

6. Copy the following info from the registration page:
  - OAuth 2.0 Client ID 
  - Client secret
  - callback URL
  - Authorization URI
  - Access/Refresh Token Request URI

Note: Technically the last two won't change, but it doesn't hurt to verify them as you'll see them in the code.

7. Duplicate the files BuildConfig/debug.xcconfig and BuildConfig/release.xcconfig
8. Edit those files and enter the Client ID and Client Secret into both of them. No quotes around them.
9. If you used a different callback URL, there's a number of places in the code that it will need to be changed.
- 
- 
- 
- 
10. Try running the project, it should launch in a simulator, but will work normally. See if you can log into Fitbit and sync your data. If it's all working, you can connect your phone to your computer and change the device to run it on. The app will stay on your phone even after you're done running it in XCode.


### Development Details

This app is written mostly in Swift 3/4, although I also used the project as a chance to really dive into Swift instead of just a passing familiarity. Also, I don't claim to be an expert iOS developer, as my programming experience has involved almost as many languages as projects. 

Specifically some of the design patterns in iOS are not second nature to me, and I'm sure this code could be more elegant especially in those areas. Also as this was mostly a personal project, there is no comprehensive testing other than sanity checks on parameters and such.

AriaSync is not localized, nor prepared for localization.


### Fitbit API details

Part of the impitus for this app was that [SyncSolver](http://syncsolver.com) downloads data from the Fitbit API in a way that included interpolated data. For example, if you weighted yourself on January 1st and January 5st, Fitbit would send records for every day in January:

Jan 1st: 150 lbs - actual scale record
Jan 2nd: 151 lbs
Jan 3nd: 152 lbs
Jan 4nd: 153 lbs
Jan 5nd: 154 lbs - actual scale record

The reason to use this API is that it allows very large date ranges in one call, so if you are requesting many different types of records (weight, steps, runs, etc), you can get a lot of data in very few calls, and since Fitbit limits the number of calls per hour, this can avoid a lot of problems.  Also, many people might not care about interpolated data, but if you have large gaps in usage, the data stops making much sense.

I wanted only actual measurements from the Aria scale, and Fitbit provides nothing in the responses to indicate which are interpolated data points. So I created AriaSync and used a different API method that only returns actual records, but is limited to retrieving 31 days of data at a time.

Since AriaSync is only retrieving one type of data, the risk of running into the API limits are minimal and can be easily avoided. Also, they only come into play when trying to access more than 12 years of data at once, and since that would be a one time inital load, it can easily be broken down into separate runs.


  ### Acknowledgements
  
  AriaSync uses the [OAuth2](https://github.com/p2/OAuth2) framework for authenticating to the Fitbit API. Thanks to all the contributers of that project for their work.
  
  
  ### License
  
  This code is released under the MIT license.
