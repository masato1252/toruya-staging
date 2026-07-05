import axios from "axios";
import safeAwait from "safe-await";
import { configureCompatAxios } from "./compat_api";

configureCompatAxios();

const request = (options) => {
  return safeAwait(axios(options));
};

export default request;
