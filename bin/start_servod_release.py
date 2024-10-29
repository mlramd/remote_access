#!/usr/bin/env python3
# Copyright 2022 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import docker
import logging
import argparse

#IMAGE = "us-docker.pkg.dev/chromeos-hw-tools/servod/servod:release"
#IMAGE = "us-docker.pkg.dev/chromeos-hw-tools/servod/servod:beta"
IMAGE = "us-docker.pkg.dev/chromeos-hw-tools/servod/servod_multi:release"


def setup():
    client = docker.from_env()
    try:
        client.images.pull(IMAGE)
    except docker.errors.APIError:
        logging.exception("Failed to pull image")
    return client


def start_servod(client, dut_hostname, board, model, serial_no, port, update):
    environment = [
        "BOARD=%s" % board,
        "MODEL=%s" % model,
        "SERIAL=%s" % serial_no,
        "PORT=%s" % port,
    ]

    name = "%s-docker_servod_%s_%s" % (dut_hostname, board, port)
    logs_volume = "%s_log" % dut_hostname

    if update:
        command = ["servo_updater", "-b", board, "-s", serial_no]
    else:
        command = ["bash", "start_servod.sh"]

    cont = client.containers.run(
        IMAGE,
        remove=True,
        privileged=True,
        name=name,
        hostname=name,
        cap_add=["NET_ADMIN"],
        detach=True,
        volumes=["/dev:/dev", "%s:/var/log/servod_%s/" % (logs_volume, port)],
        environment=environment,
        command=command,
    )
    log_lines = cont.logs(stream=True, follow=True)
    started = False
    while log_lines and not started:
        cont.reload()
        for line in log_lines:
            print(line.decode("utf-8").strip())
            if b"servod - INFO - Listening on 0.0.0.0 port" in line:
                started = True
                logging.info("Detected servod has started.")
                break
        if cont.status == "removing":
            break


if __name__ == "__main__":
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument(
        "-h",
        "--hostname",
        required=True,
        type=str,
        help="The IP or hostname of the DUT connected to servo.",
    )
    parser.add_argument(
        "-b", "--board", required=True, type=str, help="The board of the DUT."
    )
    parser.add_argument(
        "-m", "--model", required=True, type=str, help="The model of the DUT."
    )
    parser.add_argument(
        "-p", "--port", required=True, type=str, help="Port number to use"
    )
    parser.add_argument(
        "-s",
        "--serial",
        required=True,
        type=str,
        help="The serial number of the servo.",
    )
    parser.add_argument(
        "-u", "--update", required=False, action="store_true", help="Update the servo firmware"
        )
    args = parser.parse_args()
    client = setup()
    start_servod(
        client, args.hostname, args.board, args.model, args.serial, args.port, args.update
    )
