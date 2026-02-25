const express = require("express");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");

const app = express();
const port = 3000;

app.use(bodyParser.json());

mongoose.connect(
  "mongodb+srv://levanquang:tDc44kJBu5z6w5ZW@cluster0.wjy9tav.mongodb.net/?appName=Cluster0"
);
const db = mongoose.connection;
db.on("error", (error) => console.error(error));
db.once("open", () => console.log("Connect to Database"));

app.put("/:id", async (req, res) => {
  const id = req.params.id;
  await User.findByIdAndUpdate(
    id,
    { $set: { name: "new name" } },
    { new: true }
  );
  res.json("Update successfully");
});

app.listen(port, () => {
  console.log(`Server is running on ${port}`);
});

const { Schema, model } = mongoose;
const userSchema = new Schema({
  name: String,
  age: Number,
  email: String,
});

const User = model("User", userSchema);
