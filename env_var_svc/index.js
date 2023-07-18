const express = require('express')
const app = express()
const port = 8080

data = {
    MY_ENV_VAR_0: "hello world",
    MY_ENV_VAR_1: `${process.env.MY_ENV_VAR_1}`,
    MY_ENV_VAR_2: `${process.env.MY_ENV_VAR_2}`,
    MY_ENV_VAR_3: `${process.env.MY_ENV_VAR_3}`,
}

app.get('/', (req, res) => {
    res.json(data)
})

app.listen(port, () => {
    console.log(`Example app listening on port ${port}`)
})


