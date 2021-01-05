import useSWR from 'swr'
import axios from "axios";

const fetcher = (url, paramsString) => {
  let params = JSON.parse(paramsString);

  return axios({
    method: "GET",
    url: url,
    params: params,
    responseType: "json"
  }).then(response => response.data)
}

const useSchedule = ({url, scheduleParams}) => {
  const { data } = useSWR([url, JSON.stringify(scheduleParams)], fetcher)

  return {
    schedules: data,
    isLoading: !data
  }
}

export default useSchedule

