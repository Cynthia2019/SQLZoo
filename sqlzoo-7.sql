-- MORE ON JOIN

--1. List the films where the yr is 1962 [Show id, title]
SELECT id, title
 FROM movie
 WHERE yr=1962

--2. Give year of 'Citizen Kane'.
SELECT yr 
FROM movie
WHERE title = 'Citizen Kane'

--3. List all of the Star Trek movies, include the id, title and yr (all of these movies include the words Star Trek in the title). Order results by year.
SELECT id, title, yr 
FROM movie
WHERE title LIKE '%Star Trek%'
ORDER BY yr

--4. What id number does the actor 'Glenn Close' have?
SELECT id FROM actor 
WHERE name = 'Glenn Close'

--5. What is the id of the film 'Casablanca'
SELECT id FROM movie WHERE title = 'Casablanca'

--6. Obtain the cast list for 'Casablanca'.
SELECT name 
FROM actor
JOIN casting ON actor.id = casting.actorid
JOIN movie ON movie.id = casting.movieid
WHERE movieid = 27

--7. Obtain the cast list for the film 'Alien'
SELECT name 
FROM actor 
JOIN casting ON actor.id = casting.actorid
JOIN movie ON movie.id = casting.movieid
WHERE movie.title = 'Alien'

--8. List the films in which 'Harrison Ford' has appeared
SELECT title FROM movie
JOIN casting ON movie.id = casting.movieid
JOIN actor ON actor.id = casting.actorid
WHERE actor.name = 'Harrison Ford';

--9. List the films where 'Harrison Ford' has appeared - but not in the starring role. [Note: the ord field of casting gives the position of the actor. 
SELECT title FROM movie
JOIN casting ON movie.id = casting.movieid
JOIN actor ON actor.id = casting.actorid
WHERE actor.name = 'Harrison Ford' AND casting.ord != 1;

--10. List the films together with the leading star for all 1962 films.
SELECT movie.title, actor.name FROM movie
JOIN casting ON movie.id = casting.movieid 
JOIN actor ON actor.id = casting.actorid
WHERE movie.yr = 1962
AND casting.ord = 1

--12. List the film title and the leading actor for all of the films 'Julie Andrews' played in.
SELECT movie.title, actor.name 
FROM movie JOIN casting ON (movie.id = casting.movieid 
                           AND casting.ord = 1) 
           JOIN actor ON actor.id = casting.actorid
WHERE movie.id IN ( 
  SELECT movieid FROM casting --this select: return the list of ids in which Julie Andrews was
    WHERE casting.actorid IN ( 
      SELECT id FROM actor --this select: return the id for Julie Andrews
        WHERE name = 'Julie Andrews'))

--13. Obtain a list, in alphabetical order, of actors who've had at least 15 starring roles.
SELECT name 
FROM actor JOIN casting ON (casting.actorid = actor.id 
                            AND 
                            casting.ord = 1) -- only join actors who are leading role in at least 1 movie)
GROUP BY actor.name 
HAVING COUNT(*) >= 15 --if this actor's name appeared more than 15 times, than he/she has been a leading role for at least 15 times
ORDER BY name

--14. List the films released in the year 1978 ordered by the number of actors in the cast, then by title.
SELECT title, COUNT(casting.actorid)
FROM movie JOIN casting ON movie.id = casting.movieid
WHERE yr = 1978
GROUP BY movie.title
ORDER BY COUNT(casting.actorid) DESC, title 

--15.List all the people who have worked with 'Art Garfunkel'.
SELECT DISTINCT name 
FROM actor JOIN casting ON casting.actorid = actor.id
WHERE name != 'Art Garfunkel' --exclude himself from the result
AND casting.movieid IN (
  SELECT id FROM movie JOIN casting ON movieid = id -- return all the ids of the movie that Art Garfunkel was part of
    WHERE casting.actorid IN ( 
      SELECT id FROM actor WHERE name = 'Art Garfunkel')) --return the id of Art Garfunker
