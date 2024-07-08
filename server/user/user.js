const mongoose = require('mongoose');

const userSchema = mongoose.Schema({
    firstName:{
        type:String,
        required:true,
    },
    lastName:{
        type:String,
    },
    email:{
        type:String,
        required:true,
        unique:true,
    },
    fcmToken:{
        type:String,
        required:true,
        unique:true,
    }
});

const User = mongoose.model('User', userSchema);
module.exports ={User};