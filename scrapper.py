# -*- coding: utf-8 -*-
"""
Created on Sat Jun 12 09:30:28 2021

@author: sadlo
"""
# %%
import requests
from bs4 import BeautifulSoup
import pandas as pd
# %%
# Process a single row from the table
def processTableRow(item):
    team_name = item.select("span.fi-t__nText")[0].getText();
    points = item.select("td.fi-table__points")[0].getText();
    return [team_name, points]
# %% Service to scrap a selected FIFA ranking
def scrapFifaRanking(rankId, rankName):
    req = requests.get("https://www.fifa.com/fifa-world-ranking/ranking-table/men/rank/id" + rankId + "/");
    soup = BeautifulSoup(req.content, "lxml");
    rank_table = soup.select("table#rank-table")[0];    
    # Process all fetched rows
    fifa_ranking = [processTableRow(it) for it in rank_table.find_all("tr")[1:]];
    # Export
    pd.DataFrame(fifa_ranking, columns=["Country", "FIFA"]).\
        to_csv(rankName + ".csv", index=False);
# %%
# Scrap the two rankings of interest
for ranking in [("11475", "FIFA2016"),
        ("12210", "FIFA2018"),
        ("13295", "FIFA2021")]:
    scrapFifaRanking(*ranking);