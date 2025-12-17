
import { config } from "@matchlighter/fetcher"
import axios, { Axios } from "axios"
import LocalTime from "local-time"
LocalTime.start()

config.api.backend = new Axios({
    ...axios.defaults,
    baseURL: "/api/v1/",
    headers: {
        "Content-Type": "application/json",
        'Accept': "application/json",
    },
    withCredentials: true,
})

import "material-symbols";
import "@/screen.less";
