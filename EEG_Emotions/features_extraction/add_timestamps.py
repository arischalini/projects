#!/usr/bin/env python
# -*- coding: utf-8 -*-


import os, sys
import numpy as np
import pandas as pd


def add_timestamps(directory_path, drop_last_column=False):
    print("Directory path:", directory_path)

    for x in os.listdir(directory_path):
        print("RRRR x:",x)
        df=pd.read_csv(directory_path + "/" + x, sep=',')

        if (drop_last_column):
          #drop the last unknown column due to extra comma
          df.drop(df.columns[len(df.columns)-1], axis=1, inplace=True)

        from datetime import datetime
        import time

        timestamps = []
        for i in range(len(df)): #range(250):
          # sleep 4 microseconds
          time.sleep(4000/1000000.0)
          # print("i:",i,"timestamp:","%.3f" % round(time.time(),3))
          timestamps.append("%.3f" % round(time.time(),3))

        df.insert(0, "timestamps", timestamps)

        df.to_csv(directory_path + "_with_timestamps/" + x, index=False)

    return None


if __name__ == '__main__':
	"""
	Main function. The parameters for the script are the following:
		[1] directory_path: The directory where the script will look for the files to process.
		[2] output_file: The filename of the generated output file.
	
	ATTENTION: It will ignore the last column of the CSV file. 
	
	Author:
		Original by [lmanso]
		Documentation: [fcampelo]
"""

	if len(sys.argv) < 2:
		print ('arg1: input dir\narg2: output file')
		sys.exit(-1)
	directory_path = sys.argv[1]
	add_timestamps(directory_path)
