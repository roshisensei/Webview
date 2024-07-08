const admin = require("firebase-admin");
const serviceAccount = require("../config/push_notification_key.json");
const express = require('express');
const { User } = require("../user/user");

const NotifRouter =express.Router();

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

NotifRouter.post('/send-notification', async(req, res)=>{
    const {title, body, fcmToken} = req.body;
    try {   
      console.log(fcmToken);
        // const userData = await User.findOne({email});
        // if(userData){
        //     return res.status(400).json({message: 'no email exist'});
        // }
        // else{

        // fF6aaIFhQMOL_KjkTBJRcE:APA91bFpNG8t8yDFno67nwqXAP1GHcS26-3dOPuxtvHmXqczu-N9OpmU6m9OiGnEX5ctpJslgd7lKEBvlQk7m5gl_CSLEEnH6L9NmHgSTGRGHJyUzb9dnel0cYH0kzjxCGvDKmm3AUzm

            // const fcmToken = userData.fcmToken;
            // Prepare the FCM message
            const message = {
                token: fcmToken,
                notification: {
                  title: title,
                  body: body
                },
                
              };
                      // Send the FCM message
        const response = await admin.messaging().send(message);
        console.log("Successfully sent message:", response);
        return res.status(201).json({message:'Notification sent'});
        // }
      } catch (error) {
        console.error("Error sending message:", error);
        throw error;
      }
})

module.exports =NotifRouter;


  