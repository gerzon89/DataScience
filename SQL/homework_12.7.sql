use college;

/*2.	תרגיל*/
/*a.	מנהל המכללה ביקש לדעת כמה סטודנטים יש לפי יחידה (מחלקה).*/
select
de.DepartmentName
,count(StudentId) as students
from dbo.classrooms cl
left join dbo.courses co on cl.CourseId=co.CourseId
left join dbo.departments de on co.DepartmentID=de.DepartmentID
group by de.DepartmentName

/*b.	המורה באנגלית צריך להתארגן וביקש לדעת כמה סטודנטים יש לו לפי כל קורס שהוא מעביר וסה"כ התלמידים בכל הקורסים שלו.*/
select *
into #english_teacher
from dbo.courses 
where DepartmentID=(select DepartmentId from dbo.departments where DepartmentName='English')

select * from #english_teacher

select 
en.coursename
,count(cl.StudentId) as students
into #ENstudents_bycourse
from dbo.Classrooms cl
left join  #english_teacher en on cl.CourseId=en.CourseId

where cl.courseid in (1,2,3)
group by en.coursename

select 
sum(students) as total_cnt
from #ENstudents_bycourse

/*c.	המרכז למדעים רוצה להבין כמה כיתות קטנות (מתחת ל-22) וכמה גדולות צריך עבור קורסים ביחידה (מחלקה) שלו.*/
drop table #science_classrooms

select 
co.CourseName
,count(cl.studentid) as students

into #science_classrooms
from 
dbo.classrooms cl
left join dbo.courses co on cl.courseid=co.courseid


where cl.courseid in
	(select courseid from dbo.courses where departmentid=
			(select DepartmentId from dbo.departments where DepartmentName = 'Science'))
group by co.CourseName

select * from #science_classrooms

select 
CourseName
,case when students<22 then 'less then 22'
	    else '22 and more' end as class_cat
into #science_classrooms2
from #science_classrooms

select 
class_cat
,count(CourseName) as courses
from #science_classrooms2
group by class_cat

/*d.	סטודנטית שהיא פעילה פמיניסטית טוענת שהמכללה מעדיפה לקבל יותר גברים מאשר נשים. תבדקו האם הטענה מוצדקת (מבחינת כמותית, לא סטטיסטית).*/
select distinct
Gender
,count(StudentId) as students
from dbo.students
group by Gender

/*e.	באיזה קורסים אחוז הגברים / הנשים הינה מעל 70%?*/
drop table #feminist_college

select
co.coursename 
/*,cl.studentid*/
,st.Gender
,count(cl.studentid) as students
into #feminist_college 
from dbo.classrooms cl 
	left join dbo.students st on cl.StudentId=st.StudentId
	left join dbo.courses co on cl.courseid=co.courseid
group by co.coursename, st.Gender
select * from #feminist_college

select 
coursename
,sum(case when Gender='M' then students else 0 end) as males
,sum(case when Gender='F' then students else 0 end) as females
into #feminist_college2
from #feminist_college
group by coursename
select * from #feminist_college2

select coursename
from #feminist_college2
where females/males>0.7

/*f.	בכל אחד מהיחידות (מחלקות), כמה סטודנטים (מספר ואחוזים) עברו עם ציון מעל 80?*/
drop table #over80

select 
CourseId	
,StudentId	
,degree
,case when degree>=80 then 1 else 0 end as over80
,case when degree<80 then 1 else 0 end as under80
into #over80
from dbo.classrooms

select 
coursename
,sum(over80) as over80
,sum(over80)*1.0/(sum(over80)*1.0+sum(under80)*1.0)*1.0  as over80byP 
from #over80 o left join dbo.courses co on o.CourseId=co.CourseId
group by coursename


/*g.	בכל אחד מהיחידות (מחלקות), כמה סטודנטים (מספר ואחוזים) לא עברו (ציון מתחת ל-60) ?*/
drop table #failed
select 
CourseId	
,StudentId	
,degree
,case when degree<60 then 1 else 0 end as failed

into #failed
from dbo.classrooms

select 
coursename
,sum(failed) as failed
,sum(failed)*1.0/count(StudentId)*1.0  as failedbyP 
from #failed o left join dbo.courses co on o.CourseId=co.CourseId
group by coursename

/*h.	תדרגו את המורים לפי ממוצע הציון של הסטודנטים מהגבוהה לנמוך.*/

select 
te.TeacherId,te.FirstName,te.LastName
,avg(cl.degree) as avg_degree

from dbo.classrooms cl 
	left join dbo.courses co on cl.CourseId=co.CourseId
	left join dbo.teachers te on co.TeacherId=te.TeacherId
group by te.TeacherId,te.FirstName,te.LastName
order by avg(cl.degree) desc

/*3.	VIEW*/
/*a.	תייצרו VIEW המראה את הקורסים, היחידות (מחלקות) עליהם משויכים, המרצה בכל קורס ומספר התלמידים רשומים בקורס*/
drop view college
create view college as
select 
co.CourseName
,de.DepartmentName
,te.FirstName as profesorsFirstName,te.LastName as profesorsLastName
,count(cl.StudentId) as students

from dbo.classrooms cl
	left join dbo.courses co on cl.CourseId=co.CourseId
	left join dbo.teachers te on co.TeacherId=te.TeacherId
	left join dbo.departments de on co.DepartmentID=de.DepartmentID
group by co.CourseName,de.DepartmentName,te.FirstName,te.LastName

select * from college
/*b.	תייצרו VIEW המראה את התלמידים, מס' הקורסים שהם לוקחים,הממוצע של הציונים לפי יחידה (מחלקה) והממוצע הכוללת שלהם.*/
drop view studentsview

create view studentsbydept as
select
st.FirstName as StudentsFirstName,st.LastName as StudentsLastName
,de.DepartmentName
,avg(cl.degree) as DEPTAvg
from dbo.classrooms cl
	left join dbo.courses co on cl.CourseId=co.CourseId
	left join dbo.students st on cl.StudentId=st.StudentId
	left join dbo.departments de on co.DepartmentID=de.DepartmentID
group by st.FirstName,st.LastName,de.DepartmentName
select * from studentsbydept

create view studentsbyall as
select
st.FirstName as StudentsFirstName,st.LastName as StudentsLastName
,avg(cl.degree) as TOTALAvg
,count(cl.CourseId) as TOTALCnt

from dbo.classrooms cl
	left join dbo.courses co on cl.CourseId=co.CourseId
	left join dbo.students st on cl.StudentId=st.StudentId
	left join dbo.departments de on co.DepartmentID=de.DepartmentID
group by st.FirstName,st.LastName
select * from studentsbyall



