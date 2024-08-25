// import necessary module
import http from "k6/http";
import { check } from 'k6';

export const options = {
  // define thresholds
  thresholds: {
    http_req_failed: ['rate<0.01'], // http errors should be less than 1%
    http_req_duration: [ { threshold: 'p(99)<2000', abortOnFail: true} ], // 99% of requests should be below 2s
  },
  // define scenarios
  scenarios: {
    breaking: {
      executor: "ramping-vus",
      stages: [
        { duration: "5s", target: 5 },
        { duration: "5s", target: 100 },
        { duration: "10s", target: 200 },
        { duration: "5s", target: 0 }, // scale down. (optional)
      ],
    },
  }
};



export default function () {
  
  // define URL and payload
  var sut_api_url = 'http://localhost:8080';
  if (__ENV.SUT_API_URL === undefined) {
    console.log("SUT_API_URL is not set, using default http://localhost:8080");

  } else {
    console.log(`SUT_API_URL is set to ${__ENV.SUT_API_URL}`);
    sut_api_url = `${__ENV.SUT_API_URL}`;
  }
  
  const url = sut_api_url+'/cpu';


  const res = http.get(url);

  // check that response is 200
  check(res, {
    'response code was 200': (res) => res.status == 200,
  });
  console.log(res.body);

}

