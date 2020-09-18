R Intro - Final Exercise


library(DBI)
library(dplyr)

### In windows, Using a ODBC DNS (predefined connection name)
### Some possible strings for the driver:
### the DSN must be the same as you created in the ODBC (check it!)
#driver <- "Driver={SQL Server};DSN=COLLEGE;Trusted_Connection=yes;"

#driver <- "Driver={SQL Server Native Connection 11.0};DSN=COLLEGE;Trusted_Connection=True;"

### XXXXX\\XXXXX is the name of the server as it appears in the SQL server management studio
### COLLEGE is the name of the database (check how do you called it in your local server)
#driver <- "Driver={SQL Server Native Connection 11.0};Server=XXXXX\\XXXXX;Database=COLLEGE;Trusted_Connection=True;"


### Try with the diferent driver strings to see what works for you
#conn <- dbConnect(odbc::odbc, .connection_string = driver)


### Get the students table
#students = dbQuery(conn, "SELECT * FROM Students")

#dbDisconnect(conn)

conn <- DBI::dbConnect(odbc::odbc(), 
                       Driver = "SQL Server", 
                       Server = "localhost\\SQLEXPRESS",
                       Database = "COLLEGE",
                       Trusted_Connection = "True")
Classrooms<-dbGetQuery(conn,'SELECT*FROM"COLLEGE"."dbo"."Classrooms"')
Courses<-dbGetQuery(conn,'SELECT*FROM"COLLEGE"."dbo"."Courses"')
Departments<-dbGetQuery(conn,'SELECT*FROM"COLLEGE"."dbo"."Departments"')
Students<-dbGetQuery(conn,'SELECT*FROM"COLLEGE"."dbo"."Students"')
Teachers<-dbGetQuery(conn,'SELECT*FROM"COLLEGE"."dbo"."Teachers"')

dbDisconnect(conn)

Classrooms <- Classrooms[complete.cases(Classrooms), ]
View(Classrooms)
Courses <- Courses[complete.cases(Courses), ]
View(Courses)
Departments <- Departments[complete.cases(Departments), ]
Departments$DepartmentID <- Departments$DepartmentId
View(Departments)
Students <- Students[complete.cases(Students), ]
View(Students)
Teachers <- Teachers[complete.cases(Teachers), ]
View(Teachers)

  
Courses <- inner_join(Courses,Departments, by="DepartmentID")
View(Courses)
                
#Questions
#Q1. Count the number of students on each department


cors_clas <- inner_join(Courses, Classrooms, by="CourseId")
View(cors_clas)

std_dep <- cors_clas %>%
  group_by(DepartmentName.x) %>%
    transmute(StudendtNum = n_distinct(StudentId))

std_dep<-group_by(std_dep, DepartmentName.x) %>% slice(1)

View(std_dep)


#Q2. How many students have each course of the English department and the total number of students in the department?


Eng_dep<-cors_clas%>%filter(DepartmentName.x=="English")
Eng_dep

std_Eng<-Eng_dep %>% group_by(CourseName) %>% summarise(std_total = n())

View(std_Eng)

std_Eng_dis<-group_by(Eng_dep,StudentId) %>%slice(1)

std_Eng_total<-std_Eng_dis %>% group_by(DepartmentName.x) %>% tally()
View(std_Eng_total)


#Q3. How many small (<22 students) and large (22+ students) classrooms are needed for the Science department?

Science_dep<-cors_clas%>%filter(DepartmentName.x=="Science")
Science_dep

std_Science<-Scn_dep %>% group_by(CourseName) %>% summarise(cnt = n())

std_Science

std_Science$Classroom_Size <- ifelse(std_Science$cnt<=22,"Small",
                                               ifelse(std_Science$cnt>22,"Big","NA"))


std_Scn_size<-std_Scn %>% group_by(Classroom_Size) %>% summarise(cnt = n())

std_Scn_size


#Q4. A feminist student claims that there are more male than female in the College. Justify if the argument is correct

std_gender<-Students %>% group_by(Gender) %>% summarise(cnt = n())
std_gender

#Q5. For which courses the percentage of male/female students is over 70%?

std_clas <- inner_join(Students, Classrooms, by="StudentId")
head(std_clas)

std_clas_name <- inner_join(std_clas, Courses, by="CourseId")
std_clas_name

crs_Gender<-std_clas_name %>%
  group_by(Gender, CourseName) %>%
  transmute(StudendNumG = n_distinct(StudentId))

crs_Gender<-group_by(crs_Gender, Gender,CourseName) %>% slice(1)
crs_Gender

Course_tot<-std_clas_name %>%
  group_by(CourseName) %>%
  transmute(StudendNumT = n_distinct(StudentId))

Course_tot<-group_by(Course_tot, CourseName) %>% slice(1)
Course_tot

Gender_per <- inner_join(crs_Gender, Course_tot, by="CourseName")
Gender_per

Gender_per<-Gender_per %>% mutate(Per=(StudendNumG/StudendNumT)*100)
Gender_per

Gender70<-Gender_per %>% filter(Per>70)
Gender70


#Q6. For each department, how many students passed with a grades over 80?

Degree80<-cors_clas %>% filter(degree>80)
Degree80

Degree80_dis<-group_by(Degree80, StudentId, DepartmentName.x) %>% slice(1)
Degree80_dis

Degree80_std<-Degree80_dis %>%
  group_by(DepartmentName.x) %>%
  summarise(students80 = n())
Degree80_std


Degree80_per<- Degree80_std %>%
  inner_join(std_dep, by=c("DepartmentName.x"))
Degree80_per

Degree80_per<- Degree80_per %>%
  group_by(DepartmentName.x) %>%
  mutate( per= (students80*1.0/ StudendtNum)*100.0) 
Degree80_per


#Q7. For each department, how many students passed with a grades under 60?
head(cors_clas)
Degree60<-cors_clas %>% filter(degree<60)
head(Degree60)

Degree60_dis<-group_by(Degree60, StudentId, DepartmentName.x) %>% slice(1)
head(Degree60_dis)

Degree60_std<-Degree60_dis %>%
  group_by(DepartmentName.x) %>%
  summarise(students60 = n())
head(Degree60_std)

Degree60_per<- Degree60_std %>%
  inner_join(std_dep, by=c("DepartmentName.x"))
Degree60_per

Degree60_per<- Degree60_per %>%
  group_by(DepartmentName.x) %>%
  mutate( per= (students60*1.0/ StudendtNum)*100.0) 
Degree60_per


#Q8. Rate the teachers by their average student's grades (in descending order).

Degree_Teach<- Teachers %>%
  inner_join(cors_clas, by=c("TeacherId"))%>%
  select(FirstName,LastName,TeacherId,degree)
Degree_Teach

Degree_Teach_mean<-Degree_Teach %>%
  group_by(FirstName,LastName) %>%
  summarise(degree_mean = mean(degree))
Degree_Teach_mean

Degree_Teach_mean<-Degree_Teach_mean %>%
  arrange(desc(degree_mean))
Degree_Teach_mean


#Q9. Create a dataframe showing the courses, departments they are associated with, the teacher in each course, and the number of students enrolled in the course (for each course, department and teacher show the names).

cors_clas1 <- full_join(Courses, Classrooms, by="CourseId")
head(cors_clas1)

cors_clas_T<- Teachers %>%
  full_join(cors_clas1, by=c("TeacherId"))%>%
  select(CourseId,CourseName,DepartmentName.x,FirstName,LastName,TeacherId,StudentId)
cors_clas_T

cors_clas_TName<-cors_clas_T %>%
  group_by(CourseId,CourseName,DepartmentName.x, TeacherId, FirstName, LastName) %>%
  summarise(StudendtNum = n_distinct(StudentId,na.rm = TRUE))
head(cors_clas_TName)



#Q10. Create a dataframe showing the students, the number of courses they take, the average of the grades per class, and their overall average (for each student show the student name).

StudentsOV<-Classrooms %>%
  group_by(StudentId) %>%
  summarise(CourseCNT = n_distinct(CourseId),CO_degree_AVG = mean(degree))
StudentsST

StudentsSOV1<-Students %>%
  inner_join(cors_clas1, by=c("StudentId"))%>%
  select(StudentId,FirstName,LastName,DepartmentName.x,degree)
head(StudentsSOV1)

StudentsSOV2 <- tbl_df(StudentsST1) %>%
  group_by(StudentId,FirstName,LastName,DepartmentName.x) %>%
  summarize(DE_degree_AVG = mean(degree))
head(StudentsSOV2)

StudentsSOV3<-StudentsST2 %>%
  inner_join(StudentsST, by=c("StudentId"))
head(StudentsSOV3)
  





