#! /usr/bin/env python3

import json
import matplotlib.pyplot as plt
import numpy as np
import datetime
import re


class qaqc:

    def __init__(self, jdata_file):
        self.jdata_file = jdata_file
        self.data = get_json_data(self.jdata_file)
        self.rf = self.data['rf']
        self.swp = self.data['swp']

    def compare_rf_and_swp_stations(self):
        rf_keys = list(self.rf.keys())
        swp_keys = list(self.swp.keys())
        key_compare = rf_keys == swp_keys
        print(f"Total number of stations: {len(self.print_all_stations())}")
        print(f"\nRF == SWP stations in {self.jdata_file}: {key_compare}\n")
        if not key_compare:
            not_in_rf = generate_absent_stations(rf_keys, swp_keys)
            not_in_swp = generate_absent_stations(swp_keys, rf_keys)
            if not_in_rf != []:
                print_absent_stations("Not in RF:", not_in_rf)
            if not_in_swp != []:
                print_absent_stations("Not in SWP:", not_in_swp)

    def print_all_stations(self):
        """
        Create a set of all station names from the dataset.
        """
        rf_keys = list(self.rf.keys())
        swp_keys = list(self.swp.keys())
        all_keys = rf_keys + swp_keys
        return set(all_keys)

    def discarded_events(self, logfile):
        """
        Compute the number of discarded events from the log from
        extract_waveforms_7D.pbs (i.e., stderr from
        extract_event_traces.py).
        """
        all_stations = self.print_all_stations()

        print("")
        print("      Number of discarded events")
        print("          Surface wave    P-wave")
        print("================================")

        for station in all_stations:

            with open(logfile, 'r') as log:
                log_as_list = log.readlines()

                station_surface_wave_events_count = get_event_counts(
                    log_as_list, station, "Surface-wave")
                station_p_wave_events_count = get_event_counts(
                    log_as_list, station, "P-wave")

                accepted_station_surface_wave_events_count = get_wrote_stream_count(
                    log_as_list, station, "Surface-wave")
                accepted_station_p_wave_events_count = get_wrote_stream_count(
                    log_as_list, station, "P-wave")

                discarded_surface_wave_events = station_surface_wave_events_count - \
                    accepted_station_surface_wave_events_count
                discarded_p_wave_events = station_p_wave_events_count - \
                    accepted_station_p_wave_events_count

                discarded_surface_wave_events_pc = 100 * \
                    np.divide(discarded_surface_wave_events,
                              station_surface_wave_events_count)
                discarded_p_wave_events_pc = 100 * \
                    np.divide(discarded_p_wave_events,
                              station_p_wave_events_count)

                print(f"{station:10s} {discarded_surface_wave_events:4.0f} ({discarded_surface_wave_events_pc:2.0f}%) {discarded_p_wave_events:4.0f} ({discarded_p_wave_events_pc:2.0f}%)")

    def print_azim_corrections(self):

        all_stations = self.print_all_stations()

        print("{:>40s}".format("Azimuth corrections (degrees)"))
        print("{:10s} {:>10s} {:>10s} {:>10s} {:>10s}".format(
            "Station", "RF", "SWP", "SWP Unc", "|RF-SWP|"))
        print("======================================================")
        for station in all_stations:
            rf_az_corr = False
            swp_az_corr = False
            try:
                rf_az_corr = self.rf[station]['azimuth_correction']
                rf_az_corr_str = f"{rf_az_corr:.2f}"
            except KeyError:
                rf_az_corr_str = "N/A"
            try:
                swp_az_corr = self.swp[station]['azimuth_correction']
                swp_az_corr_str = f"{self.swp[station]['azimuth_correction']:.2f}"
                swp_az_unc = f"{self.swp[station]['uncertainty']:.2f}"
            except KeyError:
                swp_az_corr_str = "N/A"
                swp_az_unc = ""

            if rf_az_corr and swp_az_corr:
                az_corr_diff = f"{abs(rf_az_corr - swp_az_corr):.2f}"
            else:
                az_corr_diff = "N/A"

            print(
                f"{station:10s} {rf_az_corr_str:>10s} {swp_az_corr_str:>10s} {swp_az_unc:>10s} {az_corr_diff:>10s}")

    def repeat_stations(self):
        all_stations = list(self.print_all_stations())
        trunc_station_names = [station_root_name(i) for i in all_stations]
        repeat_stations = set(
            [x for x in trunc_station_names if trunc_station_names.count(x) > 1])
        print("Repeated station names:")
        for station in repeat_stations:
            for i in all_stations:
                if station in i:
                    print(i)
        if repeat_stations == set([]):
            print("None")
        print("")

    def plot_hist(self, bins=180):
        all_stations = list(self.print_all_stations())
        num_stations = len(all_stations)
        rf_az_plot = np.zeros([num_stations])
        swp_az_plot = np.zeros([num_stations])

        for i in np.arange(num_stations):
            try:
                rf_az_plot[i] = self.rf[all_stations[i]]['azimuth_correction']
            except KeyError:
                rf_az_plot[i] = np.nan
            try:
                swp_az_plot[i] = self.swp[all_stations[i]
                                          ]['azimuth_correction']
            except KeyError:
                swp_az_plot[i] = np.nan

        fig, axs = plt.subplots(1, 2, sharey=True)
        fonts = 25

        axs[0].set_title("RF\n azimuth corrections ($^\circ$)", fontsize=fonts)
        axs[1].set_title(
            "SWP\n azimuth corrections ($^\circ$)", fontsize=fonts)

        axs[0].hist(rf_az_plot, bins=bins)
        axs[1].hist(swp_az_plot, bins=bins)

        axs[0].tick_params(axis="both", labelsize=fonts)
        axs[1].tick_params(axis="both", labelsize=fonts)

    def date_ranges(self):
        all_stations = list(self.print_all_stations())
        print("               Data date range (days)")
        print("               RF        SWP   abs(RF-SWP)")
        for station in all_stations:
            rf_date_diff = compute_date_diff(self.rf, station, 'date_range')
            if rf_date_diff:
                rf_decimal_days = days_as_decimal(rf_date_diff)
                rf_days_str = "{0:5.1f}".format(rf_decimal_days)
            else:
                rf_days_str = "N/A"

            swp_date_diff = compute_date_diff(self.swp, station, 'date_range')
            if swp_date_diff:
                swp_decimal_days = days_as_decimal(swp_date_diff)
                swp_days_str = "{0:5.1f}".format(swp_decimal_days)
            else:
                swp_days_str = "N/A"

            if rf_date_diff and swp_date_diff:
                data_diff = abs(rf_decimal_days-swp_decimal_days)
                data_diff_str = "{0:5.1f}".format(data_diff)
            else:
                data_diff_str = ""

            print(
                f"{station:12s} {rf_days_str:10s} {swp_days_str:10s} {data_diff_str:10s}")


def compute_date_diff(dictionary, key, value):
    try:
        date_range = dictionary[key][value]
    except KeyError:
        return False
    if len(date_range) == 2:
        start_date_time = datetime.datetime.strptime(
            date_range[0], "%Y-%m-%dT%H:%M:%S.%fZ")
        stop_date_time = datetime.datetime.strptime(
            date_range[1], "%Y-%m-%dT%H:%M:%S.%fZ")
        return stop_date_time-start_date_time
    else:
        return False


def days_as_decimal(datetime_value):
    seconds_to_days = 24*60*60
    return datetime_value.total_seconds()/seconds_to_days


def generate_absent_stations(bedrock, verify):
    return [i for i in verify if i not in bedrock]


def print_absent_stations(header, print_list):
    print(f"{header}")
    for i in print_list:
        print(i)
    print("")


def get_json_data(json_file):
    with open(json_file) as jfile:
        jdata = json.load(jfile)
    return jdata


def get_event_counts(log_as_list, station, wave_type):
    wave_indexer = []
    wave_datetime_stamp = "\[{0}\]\s{1}\s\|\s(\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d)".format(
        wave_type, station)
    for item in log_as_list:
        wave_event_log = re.search(wave_datetime_stamp, item)
        if wave_event_log:
            wave_indexer.append(wave_event_log.group(1))
    return len(set(wave_indexer))


def get_wrote_stream_count(log_as_list, station, wave_type):
    wave_stream_string = "{0}:\s+Wrote\s+(\d+)\s+{1} streams to output file".format(
        station, wave_type)
    for item in log_as_list:
        stream_count = re.search(wave_stream_string, item)
        if stream_count:
            return int(stream_count.group(1))
    print(f"Check log for {station} discards.")
    return np.nan


def station_root_name(station_name):
    dot_char_separator_indices = [pos for pos, char in enumerate(station_name) if char == '.']
    network_station_index = dot_char_separator_indices[1]
    return station_name[0:network_station_index]
