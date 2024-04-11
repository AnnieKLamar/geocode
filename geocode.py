import pywikibot
import pandas as pd
import sys


def geotag(entities_file, logging=True, csv=True):
    """
    Returns a dataframe with geotagged information.
    For increased speed, set logging to False.

    :param entities_file: File with target location names from NER process.
    :param logging: if True, include print statements
    :param csv: if True, save DataFrame as .csv file
    :return: a Dataframe with coordinate information
    """
    geotagged = []
    geo_header = ['location', 'latitude', 'longitude', 'source_file']
    all_locations = open(entities_file, 'r', encoding='utf8').readlines()
    site = pywikibot.Site("en", "wikipedia")
    for location in all_locations:
        lat, long = get_wiki_coordinates(location, site, logging)
        geotagged.append([location.strip(), lat, long, entities_file])
    df = pd.DataFrame(geotagged, columns=geo_header)
    if csv:
        df.to_csv(entities_file + '_geotagged' + '.csv')
    return pd.DataFrame(geotagged, columns=geo_header)


def get_wiki_coordinates(location, site, logging):
    """
    Returns geographic coordinates from a target Wikipedia page.

    :param location: the target location to find on Wikipedia
    :param site: pywikibot Site object
    :param logging: if True include print statements
    :return: a tuple with coordinates

    Returns -100000, -100000 if page contains no geographic coordinates.
    Returns -200000, -200000 if no such Wikipedia page exists.
    """

    try:  # does direct link to page exist
        page = pywikibot.Page(site, location)
        item = pywikibot.ItemPage.fromPage(page)
        if len(item.coordinates()) > 0:
            latitude = item.coordinates()[0].lat
            longitude = item.coordinates()[0].lon
            if logging:
                print(location.strip(), latitude, longitude)
            return latitude, longitude
        else:
            if logging:
                print("No geographic data for", location)
            return -100000, -100000
    except:  # do we need to use a redirected page
        try:
            redirect_page = pywikibot.Page(site, location).getRedirectTarget()
            item = pywikibot.ItemPage.fromPage(redirect_page)
            if len(item.coordinates()) > 0:
                latitude = item.coordinates()[0].lat
                longitude = item.coordinates()[0].lon
                if logging:
                    print(location.strip(), latitude, longitude)
                return latitude, longitude
            else:
                if logging:
                    print("No geographic data for ", location)
                return -100000, -100000
        except:
            if logging:
                print("No English Wikipedia page exists for ", location)
            return -200000, -200000


def main():

    args = sys.argv[1:]
    if len(args) == 1:
        geotag(args[0], True, True)


if __name__ == "__main__":
    main()