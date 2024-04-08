# -*- coding: utf-8 -*-
"""
Created on Wed Apr  3 12:18:11 2024

@author: 123ro
"""

from shapely.geometry import Point, Polygon
from rtree import index
import json
import argparse


def run(command):
    file = open('countries.json', 'r')
    countries = json.load(file)
    file.close()

    for country in countries:
        #should_trunc  = False
        #for i in range(0, len(country['polygon'])-1):
        #    if(abs(country['polygon'][i][0]-country['polygon'][i+1][0]) >= 180):
        #        should_trunc = True
        country['polygon'] = Polygon(country['polygon'])


    file = open('trajectory.json', 'r')
    trajectory = json.load(file)
    file.close()

    for i, point in enumerate(trajectory):
        trajectory[i] = Point(point)

    """
    # Assuming you have a list of country polygons and their names
    countries = [{'name': 'Country1', 'polygon': Polygon(...)},
                 {'name': 'Country2', 'polygon': Polygon(...)}]
    """

    # Create the spatial index
    idx = index.Index()
    for pos, country in enumerate(countries):
        idx.insert(pos, country['polygon'].bounds)

    results = []
    # For each point in your trajectory
    for point in trajectory:
        # Query the index for potential country bounding boxes the point is in
        possible_countries = [countries[pos] for pos in idx.intersection((point.x, point.y, point.x, point.y))]
        
        # Check if the point is actually in the country polygon
        for country in possible_countries:
            if country['polygon'].contains(Point(point.x, point.y)):
                results.append({'name': country['name'], 'latlng': [point.y, point.x]})
                break

    file = open('results.json', 'w')
    file.write(json.dumps(results))
    file.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--uuid")
    args = parser.parse_args()
    stream_start = f"`S`T`R`E`A`M`{args.uuid}`S`T`A`R`T`"
    stream_end = f"`S`T`R`E`A`M`{args.uuid}`E`N`D`"
    while True:
        cmd = input()
        cmd = json.loads(cmd)
        try:
            result = run(cmd)
        except Exception as e:
            result = {"exception": e.__str__()}
        result = json.dumps(result)
        print(stream_start + result + stream_end)