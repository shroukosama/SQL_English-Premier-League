/********************************Evaluating salaries based on performance***********************/ 

/*1.Create a stored procedure that shows club outcomes on salaries monthly*/
/*Monthly financial plan for salary payments for each team.*/
Create PROCEDURE  sum_salaries @teamname varchar(50)
as
select pp.team_name , sum(pp.Annual_Salary)/12 as salaries_monthly
from Performance_Player pp
where @teamname=team_name
group by pp.team_name
sum_salaries @teamname= 'Liverpool'


	
/*2. Create a view that will display the player’s full name, Goals, Annual Salary,and team name for the highest goal total. */
/*Finding the relationship between scoring goals and salary (Positive relationship).*/

create view Relation_between_Goals_Annual_Salary
as
select  full_name, Goals, Annual_Salary, team_name
from Performance_Player
where Goals = (select max(Goals) from Performance_Player)
select * from Relation_between_Goals_Annual_Salary


	
/*3.create a stored procedure or a function that compares salary to 10000000 and goals to 10 if less display the message:
‘Find a better player or less expensive.*/
/*Finding players who earn annually more than 10,000,000 and scored less than 10 goals (Useless extra cost)*/

alter PROC Player_Check @team_name varchar(50)
AS
BEGIN
declare @salary money = 10000000, @goals INT = 10
  IF EXISTS ( SELECT * FROM Performance_Player
    WHERE Annual_Salary > @salary and Goals < @goals and @team_name=team_name )
	BEGIN
		select full_name as 'Find a better player or less expensive' , Team_name, Annual_Salary , Goals, position
		from Performance_Player 
		where Annual_Salary > 10000000 and goals <10 and position<> 'Goalkeeper' and @team_name=team_name
		group by full_name , Team_name,Annual_Salary , Goals, position
	END
	Else
	BEGIN
		select 'Your team is OK' as Team_Status
	END
END
EXEC  Player_Check @team_name= 'Chelsea'


	
/*4.Find players who earn less than 10,000,000 annually and score more than 10 goals 
(they have a great chance to move to another team with a higher salary commensurate with their performance).*/
Alter PROC Player_has_chance @team_name varchar(50)
AS
BEGIN
declare @salary money = 10000000, @goals INT = 10
  IF EXISTS ( SELECT * FROM Performance_Player
    WHERE Annual_Salary < @salary and Goals > @goals and @team_name=team_name )
	BEGIN
		select full_name as 'Player_has_chance' , Team_name, Annual_Salary , Goals, position
		from Performance_Player 
		where Annual_Salary < 10000000 and goals >10 and position<> 'Goalkeeper' and @team_name=team_name
		group by full_name , Team_name,Annual_Salary , Goals, position
	END
	Else
	BEGIN
		select 'Players of this team have no chance' as Team_Status
	END
END
EXEC  Player_has_chance @team_name= 'Leicester City'

	
/*5.Display the Player ID , Full Name who earns more than 1000000 Monthly.*/

select full_name, Annual_Salary, ID , team_name 
from Performance_Player 
where Annual_Salary / 12 > 1000000

	
/*6. Upgrade salary of player who scored more than 10 goals by 20 % of its last value*/

select pp.full_name ,Annual_Salary
from Performance_Player pp
where Goals > 10

update Performance_Player 
set Annual_Salary = Annual_Salary + (Annual_Salary*0.2)
where Goals > 10

	

/**************************************************Captain's performance**************************************************/


/*Evaluation of the captain's level as a team leader and scoring the highest total goals for the team.*/
/*7. Display Captain's full name, and team name for the highest goal total.*/
create view Relation_between_Performancecaptain_Team
AS
SELECT RANK() OVER (ORDER BY SUM(PP.Goals) DESC) AS rank_num, SUM(PP.Goals) AS total_goals,
Cap.full_name ,Cap.Goals, PP.team_name, Cap.Annual_Salary 
from Performance_Player PP, Performance_Player Cap 
where Cap.ID=PP.captain_ID 
GROUP BY PP.team_name , Cap.full_name , Cap.Goals, Cap.Annual_Salary

select * from Relation_between_Performancecaptain_Team

/**************************************************Team manager performance**************************************************/

/*8. If the team achieved the highest total goals, write a manager with an offensive plan.
 * If he achieves the least total goals, write a manager with a defensive plan.*/
 create proc Manager_plan @team_name varchar(20)
as
declare @goals int 
select  @goals =  sum (goals) from Performance_Player where team_name = @team_name group by team_name
if @goals >= 65
  begin
   select 'manager with an offensive plan'
  end
else 
  begin
   select 'manager with a defensive plan'
  end

exec Manager_plan @team_name = 'Manchester City'
/*********************************************************************************************/
select avg(total) as Total
from (select sum(goals) as total  
from Performance_Player
group by team_name) as team

select avg (goals) as total
from Performance_Player
where goals = (select sum(goals) from Performance_Player)
group by team_name 


	
/*9. Finding the manager and assistant for the team that achieved the highest league goals. 
Create a view that displays the name of the manager , assistant and team name  with the highest total goals.*/

create Proc MangerPerformance_TeamPerformance
As
SELECT RANK() OVER (ORDER BY SUM(PP.Goals) DESC) AS rank_num, SUM(PP.Goals) AS total_goals, 
PP.team_name, TM.Manger_name,TM.Manger_age,TM.Manger_Assistant
FROM Performance_Player PP , Team_Manger TM
Where PP.team_name = TM.team_name
GROUP BY PP.team_name, TM.Manger_name, TM.Manger_age, TM.Manger_Assistant
ORDER BY total_goals DESC
MangerPerformance_TeamPerformance

	

/*10. Create inline function that takes player id and returns team name with his manager full name*//
alter function playerinfo (@pid varchar(50)) 
returns table
	 as
	 return
	 (
	 select pp.full_name, pp.team_name , tm.Manger_name
	 from Performance_Player pp , Team_Manger tm
	 where pp.team_name = tm.team_name and pp.ID = @pid
	 )
select * from playerinfo('Liv10')


	
/*11. Finding a sponsor for each team with the highest total goals scored.
Create a view that displays the team sponsor, team name, total goals and total salary for the top 3 goal-scoring teams.*/
CREATE VIEW Relation_between_TEAM_Goals_Annual_Salary_FOR_TEAM_Sponsor 
as
SELECT top (3) SUM(pp.Goals) AS  total_goals , pp.team_name ,
SUM(pp.Annual_Salary) as highest_total_salary, ST.Sponsor
FROM Performance_Player pp , Stadium_team ST , Team_Manger TM
where pp.team_name = TM.team_name and TM.team_name = ST.team_name
group by pp.team_name , ST.Sponsor
order by total_goals DESC
SELECT * from Relation_between_TEAM_Goals_Annual_Salary_FOR_TEAM_Sponsor


	
/*****************************************Evaluate the level of the player*******************************************/

/*12. Evaluate aggressive player behavior based on red cards 
Function that displays the player with most red card and highest salary for every team*
And display message ‘aggressive player’*/
alter proc mostaggplayerinPlayer @team_name varchar (50)
as
select top 3 Red_Cards , full_name as 'Aggressive player' , Annual_Salary ,position
	 from Performance_Player
	 where team_name = @team_name
	 order by Red_Cards desc
	-- calling
EXEC  mostaggplayerinPlayer @team_name= 'Everton'

	

/*13. Select the highest two conversion rates in Each team for players.*/
SELECT Conversion_Rate, full_name,team_name, ROW_NUMBER() OVER(ORDER BY Conversion_Rate DESC) AS RowNum
FROM Performance_Player
group by team_name,Conversion_Rate,full_name

/*14.Create a stored procedure without parameters to show the maximum chances created, maximum forward passes, maximum pass accuracy.*/
alter PROCEDURE Get_Top_Player
AS
BEGIN
    SELECT TOP 1 Full_Name, Chances_Created AS Top_Chances_Created, Forward_Passes AS Top_Forward_Passes,
    Pass_Accuracy AS Top_Pass_Accuracy , team_name
    FROM Performance_Player
    ORDER BY Chances_Created DESC
END

Get_Top_Player

	
/*15. Create a view that selects a player from under-30s with most aerial duels*/
create VIEW Aerial_Duel
as
select top(3) Aerial_Duels, id, full_name, age  
from Performance_Player  
where age <30
order by Aerial_Duels desc
select * from Aerial_Duels

	
/*16. The MVP organization that selects only the starting XI players from London County selects the best players as winners.*/
/*1/16. Goalkeeper: save percentage Display top (save percentage)*/
Create view Best_Goalkeeper
As
select top(1) p.saves_rate, p.full_name ,p.id, p.position, st.county 
from Performance_Player p, Stadium_team st
where  p.team_name = st.team_name and st.county = 'london' and position = 'goalkeeper'
order by p.saves_rate desc
select * from Best_Goalkeeper

	
/*2/16. Center back: aerial duels (with minimum blocks = 20)*/
Create view Best_Center_back
As
select top(1) p.aerial_duels, p.full_name, p.ID, p.position, p.blocks, st.county
from Performance_Player p, Stadium_team st
where p.team_name = st.team_name and p.blocks>=20 and st.county = 'london'  and position = 'defender'
order by p.aerial_duels desc
select * from Best_Center_back

	
/*3/16.Center back: forward passes (with minimum pass accuracy = 90) */
Create view Best_forward_passes
As
select top(1) p.Forward_Passes, p.full_name, ID, p.position, p.pass_accuracy, st.county
from Performance_Player p, Stadium_team st
where p.team_name=st.team_name and p.pass_accuracy>=90 and st.county = 'london'  and p.position = 'defender'
order by p.forward_passes desc
select * from Best_forward_passes

	
/*4/16. Left back, Right Back: Most assists*/

Create view Best_Assists
As
select top(2) p.assists , p.position, p.full_name as winner_name, st.county 
from Performance_Player p, Stadium_team st
where st.team_name = p.team_name and p.position ='defender' and st.county = 'london' 
order by p.assists desc

select * from Best_Assists

	
/*5/16.Defensive midfielder: tackles made (with min interceptions = 45)*/

Create view Best_tackles_made
As
select top(1) p.Tackles_Made, p.full_name, p.ID, p.position, p.intraceptions, st.county
from Performance_Player p, Stadium_team st
where st.team_name = p.team_name and  p.intraceptions>=45 and st.county = 'london' and p.position = 'midfielder'
order by p.Tackles_Made desc

select * from Best_tackles_made

	
/*6/16. Central midfielder: forward pass with minimum chances created 30  */
Create view Best_Central_midfielder
As
select top(1) p.Forward_Passes, p.full_name, p.ID, p.position, p.Chances_Created, st.county
from Performance_Player p, Stadium_team st
where st.team_name = p.team_name and p.chances_created>=30 and  st.county = 'london' and p.position = 'midfielder'
order by p.Forward_Passes desc
select * from Best_Central_midfielder

	
/*7/16. (midfielder) Playmaker: most chances created with minimum assist 5. */
Create view Best_Playmaker
As
select top(1) p.Chances_Created, p.full_name, p.ID, p.position, p.Assists, st.county 
from Performance_Player p, Stadium_team st
where st.team_name = p.team_name and Assists>=5 and st.county = 'london' and position = 'midfielder'
order by p.Chances_Created desc
select * from Best_Playmaker

	
/*8/16. Right, Left winger: Most assists with minimum goals =12 */
Create view Best_Left_winger
As
select top(2)p.assists, p.full_name, p.ID, p.position, p.goals, st.county 
from Performance_Player p, Stadium_team st
where st.team_name = p.team_name and p.Goals>=12 and st.county = 'london' and position = 'forward'
order by p.assists desc

select * from Best_Left_winger

	
/*9/16. Center forward: goals with minimum conversion rate= 20 */
Create view Best_forward
As
select top(1)p.goals, p.full_name, p.ID, p.position, p.conversion_rate, st.county
from Performance_Player p, Stadium_team st
where st.team_name = p.team_name and p.conversion_rate>=20 and st.county = 'london' and position = 'forward'
order by p.conversion_rate desc
select * from Best_forward
	
///////////////***********************************************************************************////////////////////////////
/* non clusterd index to the most accessible column */
create clustered index pname
on  performance_player(full_name)
/*enable execution plan before testing*/
select full_name from Performance_Player

/////////////////////* trigger *///////////////////////////////
create trigger nomoreplayers 
on performance_player
instead of insert 
as
select 'that player didnot play in 18/19 league' as 'not allowed'

insert into performance_player 
values('abo treka' , 30 , 'defender' , 'arsenal' , 'cairo' , 4 ,2,5,4,5,6,7,14,45,5,25,77, 15 ,36,15, 42,440000,'ar27',32,66 )
