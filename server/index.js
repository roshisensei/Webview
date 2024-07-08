const express = require('express');
const app = express();
const mongoose = require('mongoose');
require('dotenv').config();
const NotifRouter = require('./notification/fcm_notification');

const PORT =process.env.PORT;
// connection to monogodb

mongoose.connect( 'mongodb://127.0.0.1:27017/fcm-notification').then(()=>
    console.log('MongoDB Connected')
).catch(err=>console.log('Mongo Error', err));


// middleware to parse json data
app.use(express.json());
app.use(NotifRouter);


app.listen(3000 ,"0.0.0.0", ()=>{
    console.log('server is started at  port: 3000');
})