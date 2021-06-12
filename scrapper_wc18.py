# -*- coding: utf-8 -*-
"""
Created on Sat Jun 12 10:20:43 2021

@author: sadlo
"""

# %%
import requests
from bs4 import BeautifulSoup
import pandas as pd

# %%
page = requests.get("https://www.fifa.com/worldcup/archive/russia2018/matches/")
soup = BeautifulSoup(page.content, "lxml")
all_games = soup.select("div.fi-matchlist div.result")

print(64 - len(all_games), "games missing")

def processMatchRow(item):
    home_team = item.select("div.home span.fi-t__nText")[0].getText().strip()
    away_team = item.select("div.away span.fi-t__nText")[0].getText().strip()
    score = item.select("span.fi-s__scoreText")[0].getText().strip()
    home_goals, away_goals = [int(goals) for goals in score.split("-")]
    return [home_team, home_goals, away_team, away_goals]

pd.DataFrame([processMatchRow(row) for row in all_games],
            columns = ["HomeTeam", "HomeGoals", "AwayTeam", "AwayGoals"]).\
to_csv("WC18.csv", index = False)