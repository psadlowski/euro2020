# -*- coding: utf-8 -*-
"""
Created on Sat Jun 12 10:03:20 2021

@author: sadlo
"""

# %%
import requests
from bs4 import BeautifulSoup
import pandas as pd
# %%
page = requests.get("https://www.uefa.com/uefaeuro/history/seasons/2016/matches/");
soup = BeautifulSoup(page.content, "lxml");
all_games = soup.select("div.match-row_match");
## /!\ The last (bottom-right) game is skipped!
print(51 - len(all_games), "games missed");
# %%
def processMatchRow(item):
    home_team = item.select("div.team-home")[0].getText().strip();
    home_goals = int(item.select("span.home-score")[0].getText().strip());
    away_team = item.select("div.team-away")[0].getText().strip();
    away_goals = int(item.select("span.away-score")[0].getText().strip());
    return [home_team, home_goals, away_team, away_goals]
# %%
pd.DataFrame([processMatchRow(row) for row in all_games],
             columns=["HomeTeam", "HomeGoals", "AwayTeam", "AwayGoals"]).\
    to_csv("EURO16.csv", index=False);