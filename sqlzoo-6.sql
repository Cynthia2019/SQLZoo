--JOIN 

--1. Modify it to show the matchid and player name for all goals scored by Germany. 
SELECT matchid, player FROM goal 
  WHERE teamid = 'GER'

--2. Show id, stadium, team1, team2 for just game 1012
SELECT id,stadium,team1,team2
  FROM game WHERE id = '1012'

--3. Modify it to show the player, teamid, stadium and mdate for every German goal.
SELECT player, teamid, stadium, mdate 
  FROM game JOIN goal ON (id=matchid)
  WHERE teamid = 'GER'

--4. Show the team1, team2 and player for every goal scored by a player called Mario player LIKE 'Mario%'
SELECT team1, team2, player 
FROM game
JOIN goal 
ON (game.id = goal.matchid)
WHERE player LIKE 'Mario%';

--5. Show player, teamid, coach, gtime for all goals scored in the first 10 minutes gtime<=10
SELECT player, teamid, coach, gtime
  FROM goal JOIN eteam ON goal.teamid = eteam.id
 WHERE gtime<=10

--6. List the dates of the matches and the name of the team in which 'Fernando Santos' was the team1 coach.
SELECT mdate, teamname
FROM game 
JOIN eteam 
ON team1 = eteam.id 
WHERE coach LIKE 'Fernando Santos'

--7. List the player for every goal scored in a game where the stadium was 'National Stadium, Warsaw'
SELECT player FROM goal 
JOIN game 
ON matchid = id
WHERE stadium = 'National Stadium, Warsaw';

--8.Instead show the name of all players who scored a goal against Germany.
SELECT DISTINCT player
  FROM game JOIN goal ON matchid = id 
    WHERE (team1 = 'GER' OR team2='GER') AND teamid !='GER'

--9. Show teamname and the total number of goals scored.
SELECT teamname, COUNT(gtime)
  FROM eteam JOIN goal ON id=teamid
 GROUP BY teamname
 ORDER BY teamname

--10. Show the stadium and the number of goals scored in each stadium.
SELECT stadium, COUNT(gtime)
FROM game JOIN goal ON id = matchid
GROUP BY stadium

--11. For every match involving 'POL', show the matchid, date and the number of goals scored.
SELECT id, mdate, COUNT(*)
FROM game 
JOIN goal 
ON goal.matchid = game.id 
WHERE (team1 = 'POL' OR team2 = 'POL')
GROUP BY game.id, game.mdate --if just group by 1, then game.mdate will not be included in the GROUP BY clause, and that's an error

--12. For every match where 'GER' scored, show matchid, match date and the number of goals scored by 'GER'
SELECT id, mdate, COUNT(*)
FROM game
JOIN goal 
ON game.id = goal.matchid
WHERE goal.teamid = 'GER'
GROUP BY game.id, game.mdate 

--13 Sort your result by mdate, matchid, team1 and team2.
SELECT game.mdate,
  team1,
  SUM(CASE WHEN teamid=team1 THEN 1 ELSE 0 END) AS score1, 
  team2,
  SUM(CASE WHEN teamid=team2 THEN 1 ELSE 0 END) AS score2
  FROM game JOIN goal ON id = matchid
  GROUP BY game.mdate, goal.matchid, game.team1, game.team2
  ORDER BY game.mdate, score1, score2