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
        key_compare = rf_keys==swp_keys
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

        print("      Number of discarded events")
        print("          Surface wave    P-wave")
        print("================================")
        for station in all_stations:
            surface_wave_indexer = 0
            primary_wave_indexer = 0
            with open(logfile, 'r') as log:

                log_in_memory = set(log.readlines())

                for line in log_in_memory:
                    surface_wave_event_log = re.search("\[Surface-wave\]\s{0}".format(station), line)
                    surface_wave_event_log = re.search("\[Surface-wave\]\s{0}".format(station), line)
                    primary_wave_event_log = re.search("\[P-wave\]\s{0}".format(station), line)
                    surface_wave_output_stream_log = re.search("{0}: Wrote\s+(\d+)\s+Surface-wave streams to output file".format(station), line)
                    primary_wave_output_stream_log = re.search("{0}: Wrote\s+(\d+)\s+P-wave streams to output file".format(station), line)
                    if surface_wave_event_log:
                        surface_wave_indexer += 1
                    if primary_wave_event_log:
                        primary_wave_indexer += 1
                    if surface_wave_output_stream_log:
                        good_surface_wave_events = int(surface_wave_output_stream_log.group(1))
                    if primary_wave_output_stream_log:
                        good_primary_wave_events = int(primary_wave_output_stream_log.group(1))

                discarded_surface_wave_events = surface_wave_indexer - good_surface_wave_events
                sw_pc = float(100*np.divide(discarded_surface_wave_events, surface_wave_indexer))

                discarded_primary_wave_events = primary_wave_indexer - good_primary_wave_events
                pw_pc = float(100*np.divide(discarded_primary_wave_events, primary_wave_indexer))

                print(f"{station:10s} {discarded_surface_wave_events:4d} ({sw_pc:2.0f}%) {discarded_primary_wave_events:4d} ({pw_pc:2.0f}%) ")



                # for line in log:
                #     surface_wave_event_log = re.search("\[Surface-wave\]\s{0}".format(station), line)
                #     primary_wave_event_log = re.search("\[P-wave\]\s{0}".format(station), line)
                #     surface_wave_output_stream_log = re.search("{0}: Wrote\s+(\d+)\s+Surface-wave streams to output file".format(station), line)
                #     primary_wave_output_stream_log = re.search("{0}: Wrote\s+(\d+)\s+P-wave streams to output file".format(station), line)
                #     if surface_wave_event_log:
                #         surface_wave_indexer.append( += 1
                #     if primary_wave_event_log:
                #         primary_wave_indexer += 1
                #     if surface_wave_output_stream_log:
                #         good_surface_wave_events = int(surface_wave_output_stream_log.group(1))
                #     if primary_wave_output_stream_log:
                #         good_primary_wave_events = int(primary_wave_output_stream_log.group(1))

                # discarded_surface_wave_events = surface_wave_indexer - good_surface_wave_events
                # sw_pc = float(100*np.divide(discarded_surface_wave_events, surface_wave_indexer))

                # discarded_primary_wave_events = primary_wave_indexer - good_primary_wave_events
                # pw_pc = float(100*np.divide(discarded_primary_wave_events, primary_wave_indexer))

                # print(f"{station:10s} {discarded_surface_wave_events:4d} ({sw_pc:2.0f}%) {discarded_primary_wave_events:4d} ({pw_pc:2.0f}%) ")



    def print_azim_corrections(self):

        all_stations = self.print_all_stations()

        print("{:>40s}".format("Azimuth corrections (degrees)"))
        print("{:10s} {:>10s} {:>10s} {:>10s} {:>10s}".format("Station", "RF", "SWP", "SWP Unc", "|RF-SWP|"))
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

            print(f"{station:10s} {rf_az_corr_str:>10s} {swp_az_corr_str:>10s} {swp_az_unc:>10s} {az_corr_diff:>10s}")


    def repeat_stations(self):
        all_stations = list(self.print_all_stations())
        trunc_station_names = [i[0:7] for i in all_stations]
        repeat_stations = set([x for x in trunc_station_names if trunc_station_names.count(x) > 1])
        print("Repeated station names:")
        for station in repeat_stations:
            for i in all_stations:
                if station in i:
                    print(i)


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
                swp_az_plot[i] = self.swp[all_stations[i]]['azimuth_correction']
            except KeyError:
                swp_az_plot[i] = np.nan

        fig, axs = plt.subplots(1, 2, sharey=True)
        fonts = 25

        axs[0].set_title("RF\n azimuth corrections ($^\circ$)", fontsize=fonts)
        axs[1].set_title("SWP\n azimuth corrections ($^\circ$)", fontsize=fonts)

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

            print(f"{station:12s} {rf_days_str:10s} {swp_days_str:10s} {data_diff_str:10s}")


def compute_date_diff(dictionary, key, value):
    try:
        date_range = dictionary[key][value]
    except KeyError:
        return False
    if len(date_range) == 2:
        start_date_time = datetime.datetime.strptime(date_range[0], "%Y-%m-%dT%H:%M:%S.%fZ")
        stop_date_time = datetime.datetime.strptime(date_range[1], "%Y-%m-%dT%H:%M:%S.%fZ")
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
