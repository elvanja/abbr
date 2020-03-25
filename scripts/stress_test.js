/*
Usage:
`k6 run -u 50 -d 10s -e HOST_URL=HOST_URL -e BASE_SHORTEN_URL=BASE_SHORTEN_URL -e MAX_URL_COUNT=MAX_URL_COUNT scripts/stress_test.js`

HOST_URL represents the base address of the service itself.

BASE_SHORTEN_URL represents the base URL you'd like to shorten.
Just make sure it doesn't already contain query parameters since stress test script appends ?q=RANDOM_NUMBER for each test thread.

MAX_URL_COUNT determines the pool size for short URLs and is not mandatory.

Each virtual user / executor:
- constructs long URL from given BASE_SHORTEN_URL and random query param (to make it unique)
- shortens that long URL, only 1st time
- runs against shortened URL
*/

import http from "k6/http";
import { check, group } from "k6";
import { Counter, Rate, Trend } from "k6/metrics";

const short_urls = {};

const create_duration = new Trend("create_duration");
const create_error_rate = new Rate("create_error_rate");
const create_500 = new Counter("create_500");
const create_503 = new Counter("create_503");

const execute_duration = new Trend("execute_duration");
const execute_error_rate = new Rate("execute_error_rate");
const execute_404 = new Counter("execute_404");
const execute_503 = new Counter("execute_503");

function create_short_url(host_url, long_url) {
    let short_url = undefined;

    group("create", function () {
        const payload = {url: long_url};

        const response = http.post(host_url + "/api/urls", JSON.stringify(payload), {
            headers: {"Content-Type": "application/json"}
        });

        if (response.status === 201) {
            short_url = JSON.parse(response.body || "{}").short_url;
        }

        const check_result = check(response, {
            "status is 201": (r) => r.status === 201,
            "short URL returned": () => short_url !== undefined
        });

        switch (response.status) {
            case 201:
                break;
            case 500:
                create_500.add(1);
                break;
            case 503:
                create_503.add(1);
                break;
            default:
                console.error(`Error creating, status: ${response.status}`);
                console.error(JSON.stringify(response));
        }

        create_duration.add(response.timings.duration);
        create_error_rate.add(!check_result);
    });

    return short_url;
}

export function setup() {
    const host_url = __ENV.HOST_URL;
    if (host_url === undefined) throw new Error("Host to test against is mandatory, please set the HOST_URL env variable");

    const base_shorten_url = __ENV.BASE_SHORTEN_URL;
    if (base_shorten_url === undefined) throw new Error("Base URL to shorten with is mandatory, please set the BASE_SHORTEN_URL env variable");

    const max_url_count = __ENV.MAX_URL_COUNT || 1000;

    return [host_url, base_shorten_url, max_url_count];
}

export default function([host_url, base_shorten_url, max_url_count]) {
    const long_url_base = base_shorten_url + "?q=" + __VU;
    const selected_index = Math.floor(Math.random() * max_url_count);
    const long_url = long_url_base + "-" + selected_index;

    let short_url = short_urls[selected_index];
    if (short_url === undefined) {
        short_url = create_short_url(host_url, long_url);
        short_urls[selected_index] = short_url;
    }

    if (short_url !== undefined) {
        group("execute", function () {
            const response = http.get(short_url, {redirects: 0});

            const check_result = check(response, {
                "status is 302": (r) => r.status === 302,
                "correct redirect": (r) => r.headers.Location === long_url
            });

            switch (response.status) {
                case 302:
                    if (response.headers.Location !== long_url) {
                        console.error(`Invalid redirect detected, short: ${short_url}, expected: ${long_url}, got: ${response.headers.Location} [${response.status}]`);
                    }
                    break;
                case 404:
                    execute_404.add(1);
                    break;
                case 503:
                    execute_503.add(1);
                    break;
                default:
                    console.error(`Error executing, status: ${response.status}`);
                    console.error(JSON.stringify(response));
            }

            execute_duration.add(response.timings.duration);
            execute_error_rate.add(!check_result);
        });
    }
}
