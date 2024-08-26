--**********************************************************************************************--
-- Title: ITFnd130Final
-- Author: JasonVerberne
-- Desc: This file demonstrates how to design and create; 
--       tables, views, and stored procedures
-- Change Log: 08/23/24 / Jason Verberne / Creation and Update
--			   08/24/24 / Jason Verberne / Updated Constraints
-- 2017-01-01,JasonVerberne,Created File
--***********************************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'ITFnd130FinalDB_JasonVerberne')
	 Begin 
	  Alter Database [ITFnd130FinalDB_JasonVerberne] set Single_user With Rollback Immediate;
	  Drop Database ITFnd130FinalDB_JasonVerberne;
	 End
	Create Database ITFnd130FinalDB_JasonVerberne;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use ITFnd130FinalDB_JasonVerberne;

-- Create Tables (Review Module 01)-- 
GO

CREATE TABLE Courses (CourseID INT IDENTITY(1, 1)
						 , CourseName NVARCHAR(100) NOT NULL
						 , CourseStartDate DATE NULL
						 , CourseEndDate DATE NULL
						 , CourseStartTime TIME NULL
						 , CourseEndTime TIME NULL
						 , CourseDaysOfWeek NVARCHAR(100) NULL
						 , CourseCurrentPrice MONEY NULL);

GO

CREATE TABLE Students (StudentID INT IDENTITY(1, 1)
						  , StudentFirstName NVARCHAR(100) NOT NULL
						  , StudentLastName NVARCHAR(100) NOT NULL
						  , StudentIDNumber NVARCHAR(100) NOT NULL
						  , StudentEmail NVARCHAR(100) NOT NULL
						  , StudentPhoneNumber NVARCHAR(14) NOT NULL
						  , StudentAddressStreetOneOnly NVARCHAR(100) NOT NULL
						  , StudentAddressStreetTwoOnly NVARCHAR(100) NULL
						  , StudentAddressCityOnly NVARCHAR(100) NOT NULL
						  , StudentAddressStateOnly NVARCHAR(2) NOT NULL
						  , StudentAddressZipOnly NVARCHAR(10) NOT NULL);

GO

CREATE TABLE Enrollments (EnrollmentID INT IDENTITY(1, 1)
					   , CourseID INT 
					   , StudentID INT 
					   , EnrollmentSignUpDate DATE NOT NULL
					   , EnrollmentPaidAmount MONEY NULL);

GO

-- Add Constraints (Review Module 02) -- 

GO

CREATE FUNCTION dbo.fDaysOfWeekVerify() -- Counts instances where string_split enrollment days not in list of days of week
RETURNS INT
AS 
	BEGIN RETURN(
		SELECT COUNT(*) 
			FROM Courses CROSS APPLY string_split(CourseDaysOfWeek, ',') 
			WHERE LTRIM(RTRIM([value])) NOT IN ('MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'))
	END

GO

ALTER TABLE Courses
	ADD CONSTRAINT pkCourses PRIMARY KEY (CourseID)
		, CONSTRAINT ucCourseName UNIQUE (CourseName) -- All course names should be unique
		, CONSTRAINT ucCourseStartDate CHECK (CourseStartDate LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]') -- Ensures YYYY-MM-DD Format
		, CONSTRAINT ucCourseEndDate CHECK (CourseEndDate LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' -- Ensures YYYY-MM-DD Format
		  AND CourseStartDate < CourseEndDate) -- Ensures start date is before end date
		, CONSTRAINT ucCourseStartTime CHECK (CourseStartTime < CourseEndTime) -- Ensures start time is before end time
		, CONSTRAINT ucCourseEndTime CHECK (CourseEndTime > CourseStartTime) -- Ensures start time is before end time
		, CONSTRAINT ucCourseDaysOfWeek CHECK (dbo.fDaysOfWeekVerify() = 0) -- Ensures CourseDaysOfWeek are first 3 letters of each day (MON, TUE, WED, THU, FRI, SAT, SUN)
		, CONSTRAINT ucCourseCurrentPrice CHECK (CourseCurrentPrice >= 0.00); -- Ensures price is greater than zero

GO

ALTER TABLE Students
	ADD CONSTRAINT pkStudents PRIMARY KEY (StudentID)
		, CONSTRAINT ucStudentIDNumber UNIQUE (StudentIDNumber) -- All student IDs should be unique
		, CONSTRAINT ucStudentEmail UNIQUE (StudentEmail) -- All student emails should be unique
		, CONSTRAINT ckStudentIDNumber CHECK (StudentIDNumber LIKE '[A-Z]-%-[0-9][0-9][0-9]') -- Ensures follows format: X-UNLIMITED_CHAR-123
		, CONSTRAINT ckStudentEmail CHECK (StudentEmail LIKE '%_@_%.__%') -- Ensure follows standard email format
		, CONSTRAINT ckStudentPhoneNumber CHECK (StudentPhoneNumber LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') -- Ensure phone follows format: 1234567890
		, CONSTRAINT ckStudentAddressStateOnly CHECK (StudentAddressStateOnly LIKE '[A-Z][A-Z]') -- Ensures states only have alpha characters
		, CONSTRAINT ckStudentAddressZipOnly CHECK (StudentAddressZipOnly LIKE '[0-9][0-9][0-9][0-9][0-9]'
													OR StudentAddressZipOnly LIKE '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'); -- Ensures 5 numbers are used for zip with or without the +4

GO

CREATE FUNCTION dbo.fLateEnrollment() -- Counts instances where enrollment date is after course start date
RETURNS INT
AS 
	BEGIN RETURN(
		SELECT COUNT(*)
		FROM Enrollments AS e INNER JOIN Courses AS c
		ON e.CourseID = c.CourseID
		WHERE e.EnrollmentSignUpDate >= c.CourseStartDate)
	END

GO

ALTER TABLE Enrollments
	ADD CONSTRAINT pkEnrollmentID PRIMARY KEY (EnrollmentID)
		, CONSTRAINT fkCourseID FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
		, CONSTRAINT fkStudentID FOREIGN KEY (StudentID) REFERENCES Students(StudentID)
		, CONSTRAINT ucEnrollmentSignUpDate CHECK (dbo.fLateEnrollment() = 0) -- Ensures enrollment is before course start date
		, CONSTRAINT dfEnrollmentSignUpDate DEFAULT(GETDATE()) for EnrollmentSignUpDate
		, CONSTRAINT ucEnrollmentPaidAmount CHECK (EnrollmentPaidAmount >= 0.00) -- Ensures paid amount is greater than zero
		, CONSTRAINT dfEnrollmentPaidAmount DEFAULT(0) FOR EnrollmentPaidAmount;

GO

-- Add Views (Review Module 03 and 06) -- 
GO

CREATE VIEW vCourses
AS
	SELECT CourseID
		   , CourseName
		   , CourseStartDate
		   , CourseEndDate
		   , CourseStartTime
		   , CourseEndTime
		   , CourseDaysOfWeek
		   , CourseCurrentPrice 
	FROM Courses

GO

CREATE VIEW vStudents
AS
	SELECT StudentID
	, StudentFirstName
	, StudentLastName
	, StudentIDNumber
	, StudentEmail
	, StudentPhoneNumber
	, StudentAddressStreetOneOnly
	, StudentAddressStreetTwoOnly
	, StudentAddressCityOnly
	, StudentAddressStateOnly
	, StudentAddressZipOnly
	FROM Students

GO

CREATE VIEW vEnrollments
AS
	SELECT EnrollmentID
	, CourseID
	, StudentID
	, EnrollmentSignUpDate
	, EnrollmentPaidAmount
	FROM Enrollments

GO

CREATE VIEW vEnrollmentTracker
AS
	SELECT c.CourseName AS [Course]
		   , CONCAT(FORMAT(c.CourseStartDate, 'MM'), '/', FORMAT(c.CourseStartDate, 'dd'), '/', FORMAT(c.CourseStartDate, 'yyyy') -- Format dates to: MM/DD/YYYY
		     , ' to '
			 , FORMAT(c.CourseEndDate, 'MM'), '/', FORMAT(c.CourseEndDate, 'dd'), '/', FORMAT(c.CourseEndDate, 'yyyy')) AS [Dates] -- Format dates to: MM/DD/YYYY
		   , c.CourseDaysOfWeek AS [Days]
		   , CONVERT(VARCHAR(5), c.CourseStartTime, 108) AS [START]
		   , CONVERT(VARCHAR(5), c.CourseEndTime, 108) AS [END]
		   , c.CourseCurrentPrice AS [Price]
		   , CONCAT(s.StudentFirstName, ' ', s.StudentLastName) AS [Student]
		   , s.StudentIDNumber AS [Number]
		   , s.StudentEmail AS [Email]
		   , CONCAT('(', SUBSTRING(s.StudentPhoneNumber, 1, 3), ') ', SUBSTRING(s.StudentPhoneNumber, 4, 3), '-', SUBSTRING(s.StudentPhoneNumber, 7, 4)) AS [Phone] -- Format phone to: (123) 456-7890
		   , CONCAT(s.StudentAddressStreetOneOnly, s.StudentAddressStreetTwoOnly,', ', s.StudentAddressCityOnly, '., ', s.StudentAddressZipOnly) AS [Address]
		   , CONCAT(FORMAT(e.EnrollmentSignUpDate, 'MM'), '/', FORMAT(e.EnrollmentSignUpDate, 'dd'), '/', FORMAT(e.EnrollmentSignUpDate, 'yyyy')) as [Signup Date] -- Format dates to: MM/DD/YYYY
		   , e.EnrollmentPaidAmount AS [Paid]
	FROM Students AS s INNER JOIN Enrollments AS e
	ON s.StudentID = e.StudentID
	INNER JOIN Courses AS c
	ON c.CourseID = e.CourseID

GO

--< Test Tables by adding Sample Data >--  
GO

INSERT INTO Courses (CourseName
					 , CourseStartDate
					 , CourseEndDate
					 , CourseStartTime
					 , CourseEndTime
					 , CourseDaysOfWeek
					 , CourseCurrentPrice)
VALUES ('SQL1-Winter 2017'
		, '1/10/2017'
		, '1/24/2017'
		, '18:00'
		, '20:50'
		, 'TUE'
		, 399)
		, ('SQL2-Winter 2017'
		, '1/31/2017'
		, '2/14/2017'
		, '18:00'
		, '20:50'
		, 'TUE'
		, 399)

GO

INSERT INTO Students (StudentFirstName
					  , StudentLastName
					  , StudentIDNumber
					  , StudentEmail
					  , StudentPhoneNumber
					  , StudentAddressStreetOneOnly
					  , StudentAddressStreetTwoOnly
					  , StudentAddressCityOnly
					  , StudentAddressStateOnly
					  , StudentAddressZipOnly)

Values ('Bob'
		, 'Smith'
		, 'B-Smith-071'
		, 'Bsmith@HipMail.com'
		, '2061112222'
		, '123 Main St.'
		, ''
		, 'Seattle'
		, 'WA'
		, '98001')
		, ('Sue'
		   , 'Jones'
		   , 'S-Jones-003'
		   , 'SueJones@YaYou.com'
		   , '2062314321'
		   , '333 1st St.'
		   , ''
		   , 'Seattle'
		   , 'WA'
		   , '98001')

GO

INSERT INTO Enrollments (CourseID
						 , StudentID
						 , EnrollmentSignUpDate
						 , EnrollmentPaidAmount)
VALUES (1
		, 1
		, '1/3/2017'
		, 399)
		, (1
		, 2
		, '12/14/2016'
		, 349)
		, (2
		, 1
		, '1/12/2017'
		, 399)
		, (2
		, 2
		, '12/14/2016'
		, 349)

GO

/*
SELECT * FROM Courses
SELECT * FROM Students
SELECT * FROM Enrollments
SELECT * FROM vCourses
SELECT * FROM vStudents
SELECT * FROM vEnrollments
SELECT * FROM vEnrollmentTracker
*/


-- Add Stored Procedures (Review Module 04 and 08) --

--====================PROCEDURES - COURSES====================
GO

CREATE PROCEDURE pInsCourses (@CourseName VARCHAR(100)
							   , @CourseStartDate DATE
							   , @CourseEndDate DATE
							   , @CourseStartTime TIME
							   , @CourseEndTime TIME
							   , @CourseDaysOfWeek NVARCHAR(100)
							   , @CourseCurrentPrice MONEY)
	AS
		BEGIN
			DECLARE @RC INT = 0
			BEGIN TRY
				BEGIN TRANSACTION
					INSERT INTO Courses (CourseName
										, CourseStartDate
										, CourseEndDate
										, CourseStartTime
										, CourseEndTime
										, CourseDaysOfWeek
										, CourseCurrentPrice)
					VALUES (@CourseName 
							, @CourseStartDate
							, @CourseEndDate
							, @CourseStartTime
							, @CourseEndTime
							, @CourseDaysOfWeek
							, @CourseCurrentPrice)
				SET @RC = +1
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				PRINT 'An error has occurred inserting course data. Please review the data you are trying to enter.'
				PRINT ERROR_NUMBER()
				PRINT ERROR_MESSAGE()
				SET @RC = -1
				ROLLBACK TRANSACTION;
			END CATCH
			RETURN @RC
		END

GO

CREATE PROCEDURE pUpdateCourses (@CourseID INT
							   , @CourseName VARCHAR(100)
							   , @CourseStartDate DATE
							   , @CourseEndDate DATE
							   , @CourseStartTime TIME
							   , @CourseEndTime TIME
							   , @CourseDaysOfWeek NVARCHAR(100)
							   , @CourseCurrentPrice MONEY)
	AS
		BEGIN
			DECLARE @RC INT = 0
			BEGIN TRY
				BEGIN TRANSACTION
					UPDATE Courses 
						SET CourseName = @CourseName
							, CourseStartDate = @CourseStartDate
							, CourseEndDate = @CourseEndDate
							, CourseStartTime = @CourseStartTime
							, CourseEndTime = @CourseEndTime
							, CourseDaysOfWeek = @CourseDaysOfWeek
							, CourseCurrentPrice = @CourseCurrentPrice
						WHERE CourseID = @CourseID
				If(@@ROWCOUNT > 1) RaisError('Do not change more than one row!', 15,1);
				SET @RC = +1
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				PRINT 'An error has occurred with updating course data. Please review the data you are trying to enter.'
				PRINT ERROR_NUMBER()
				PRINT ERROR_MESSAGE()
				SET @RC = -1
				ROLLBACK TRANSACTION;
			END CATCH
			RETURN @RC
		END

GO

CREATE PROCEDURE pDeleteCourses (@CourseID INT)
	AS
		BEGIN
			DECLARE @RC INT = 0
			BEGIN TRY
				BEGIN TRANSACTION
					DELETE FROM Enrollments 
						WHERE CourseID = @CourseID
					DELETE FROM Courses 
						WHERE CourseID = @CourseID
					If(@@ROWCOUNT > 1) RaisError('Do not delete more than one row!', 15,1);
				SET @RC = +1
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				PRINT 'An error has occurred with deleting course data. Please review the data you are trying to enter.'
				PRINT ERROR_NUMBER()
				PRINT ERROR_MESSAGE()
				SET @RC = -1
				ROLLBACK TRANSACTION;
			END CATCH
			RETURN @RC
		END

--====================PROCEDURES - STUDENTS====================
GO

CREATE PROCEDURE pInsStudents (@StudentFirstName NVARCHAR(100)
							   , @StudentLastName NVARCHAR(100) 
							   , @StudentIDNumber NVARCHAR(100)
							   , @StudentEmail NVARCHAR(100)
							   , @StudentPhoneNumber NVARCHAR(14)
							   , @StudentAddressStreetOneOnly NVARCHAR(100)
							   , @StudentAddressStreetTwoOnly NVARCHAR(100)
							   , @StudentAddressCityOnly NVARCHAR(100)
							   , @StudentAddressStateOnly NVARCHAR(2)
							   , @StudentAddressZipOnly NVARCHAR(10))
	AS
		BEGIN
			DECLARE @RC INT = 0
			BEGIN TRY
				BEGIN TRANSACTION
					INSERT INTO Students (StudentFirstName
										, StudentLastName
										, StudentIDNumber
										, StudentEmail
										, StudentPhoneNumber
										, StudentAddressStreetOneOnly
										, StudentAddressStreetTwoOnly
										, StudentAddressCityOnly
										, StudentAddressStateOnly
										, StudentAddressZipOnly)
					VALUES (@StudentFirstName
							, @StudentLastName
							, @StudentIDNumber
							, @StudentEmail
							, @StudentPhoneNumber
							, @StudentAddressStreetOneOnly
							, @StudentAddressStreetTwoOnly
							, @StudentAddressCityOnly
							, @StudentAddressStateOnly
							, @StudentAddressZipOnly)
				SET @RC = +1
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				PRINT 'An error has occurred inserting student data. Please review the data you are trying to enter.'
				PRINT ERROR_NUMBER()
				PRINT ERROR_MESSAGE()
				SET @RC = -1
				ROLLBACK TRANSACTION;
			END CATCH
			RETURN @RC
		END

GO

CREATE PROCEDURE pUpdateStudents(@StudentID INT
								 , @StudentFirstName NVARCHAR(100)
								 , @StudentLastName NVARCHAR(100) 
								 , @StudentIDNumber NVARCHAR(100)
								 , @StudentEmail NVARCHAR(100)
								 , @StudentPhoneNumber NVARCHAR(14)
								 , @StudentAddressStreetOneOnly NVARCHAR(100)
								 , @StudentAddressStreetTwoOnly NVARCHAR(100)
								 , @StudentAddressCityOnly NVARCHAR(100)
								 , @StudentAddressStateOnly NVARCHAR(2)
								 , @StudentAddressZipOnly NVARCHAR(10))
AS
	BEGIN
		DECLARE @RC INT = 0
		BEGIN TRY
			BEGIN TRANSACTION
				UPDATE Students
					SET StudentFirstName = @StudentFirstName
						, StudentLastName = @StudentLastName
						, StudentIDNumber = @StudentIDNumber
						, StudentEmail = @StudentEmail
						, StudentPhoneNumber = @StudentPhoneNumber
						, StudentAddressStreetOneOnly = @StudentAddressStreetOneOnly
						, StudentAddressStreetTwoOnly = @StudentAddressStreetTwoOnly
						, StudentAddressCityOnly = @StudentAddressCityOnly
						, StudentAddressStateOnly = @StudentAddressStateOnly
						, StudentAddressZipOnly = @StudentAddressZipOnly
					WHERE StudentID = @StudentID
			If(@@ROWCOUNT > 1) RaisError('Do not change more than one row!', 15,1);
			SET @RC = +1
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			PRINT 'An error has occurred with updating course data. Please review the data you are trying to enter.'
			PRINT ERROR_NUMBER()
			PRINT ERROR_MESSAGE()
			SET @RC = -1
			ROLLBACK TRANSACTION;
		END CATCH
		RETURN @RC
	END

GO

CREATE PROCEDURE pDeleteStudents (@StudentID INT)
AS
	BEGIN
		DECLARE @RC INT = 0
		BEGIN TRY
			BEGIN TRANSACTION
				DELETE FROM Enrollments 
						WHERE StudentID = @StudentID
				DELETE FROM Students 
					WHERE StudentID = @StudentID
				If(@@ROWCOUNT > 1) RaisError('Do not delete more than one row!', 15,1);
			SET @RC = +1
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			PRINT 'An error has occurred with deleting student data. Please review the data you are trying to enter.'
			PRINT ERROR_NUMBER()
			PRINT ERROR_MESSAGE()
			SET @RC = -1
			ROLLBACK TRANSACTION;
		END CATCH
		RETURN @RC
	END

--====================PROCEDURES - ENROLLMENTS====================
GO

CREATE PROCEDURE pInsEnrollments (@CourseID INT 
								  , @StudentID INT 
								  , @EnrollmentSignUpDate DATE
								  , @EnrollmentPaidAmount MONEY)
	AS
		BEGIN
			DECLARE @RC INT = 0
			BEGIN TRY
				BEGIN TRANSACTION
					INSERT INTO Enrollments (CourseID 
										  , StudentID 
										  , EnrollmentSignUpDate
										  , EnrollmentPaidAmount)
					VALUES (@CourseID 
							, @StudentID 
							, @EnrollmentSignUpDate
							, @EnrollmentPaidAmount)
				SET @RC = +1
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				PRINT 'An error has occurred inserting enrollment data. Please review the data you are trying to enter.'
				PRINT ERROR_NUMBER()
				PRINT ERROR_MESSAGE()
				SET @RC = -1
				ROLLBACK TRANSACTION;
			END CATCH
			RETURN @RC
		END

GO

CREATE PROCEDURE pUpdateEnrollments(@EnrollmentID INT
									, @CourseID INT 
									, @StudentID INT 
									, @EnrollmentSignUpDate DATE
									, @EnrollmentPaidAmount MONEY)
	AS
		BEGIN
			DECLARE @RC INT = 0
			BEGIN TRY
				BEGIN TRANSACTION
					UPDATE Enrollments
						SET CourseID = @CourseID
							, StudentID = @StudentID 
							, EnrollmentSignUpDate = @EnrollmentSignUpDate
							, EnrollmentPaidAmount = @EnrollmentPaidAmount
						WHERE EnrollmentID = @EnrollmentID
				If(@@ROWCOUNT > 1) RaisError('Do not change more than one row!', 15,1);
				SET @RC = +1
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				PRINT 'An error has occurred with updating enrollment data. Please review the data you are trying to enter.'
				PRINT ERROR_NUMBER()
				PRINT ERROR_MESSAGE()
				SET @RC = -1
				ROLLBACK TRANSACTION;
			END CATCH
			RETURN @RC
		END

GO

CREATE PROCEDURE pDeleteEnrollments (@EnrollmentID INT)
AS
	BEGIN
		DECLARE @RC INT = 0
		BEGIN TRY
			BEGIN TRANSACTION
				DELETE FROM Enrollments 
					WHERE EnrollmentID = @EnrollmentID
				If(@@ROWCOUNT > 1) RaisError('Do not delete more than one row!', 15,1);
			SET @RC = +1
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			PRINT 'An error has occurred with deleting enrollment data. Please review the data you are trying to enter.'
			PRINT ERROR_NUMBER()
			PRINT ERROR_MESSAGE()
			SET @RC = -1
			ROLLBACK TRANSACTION;
		END CATCH
		RETURN @RC
	END

GO
-- Set Permissions --

--====================DENY PERMISSION====================
DENY SELECT ON Courses TO Public;
Deny SELECT ON Students TO Public;
DENY SELECT ON Enrollments TO Public;

--====================GRANT PERMISSION====================
GRANT SELECT ON vCourses TO Public;
GRANT SELECT ON vStudents TO Public;
GRANT SELECT ON vEnrollments TO Public;
GRANT SELECT ON vEnrollmentTracker TO Public;


--< Test Sprocs >-- 

--====================TEST COURSES====================
GO

DECLARE @Status INT;
EXECUTE @Status = pInsCourses 'SQL1-Spring 2017'
							   , '3/10/2017'
							   , '3/24/2017'
							   , '18:00'
							   , '20:50'
							   , 'WED, THU, FRI'
							   , 399;

SELECT CASE @Status
	WHEN +1 THEN '(pInsCourses): Insert was successful'
	WHEN 0 THEN '(pInsCourses): No insert change - error'
	WHEN -1 THEN '(pInsCourses): Insert Failed!'
	End as [Status]

GO

DECLARE @Status INT;
EXECUTE @Status = pUpdateCourses 3
							   ,  'SQL1-Spring 2017'
							   , '3/10/2017'
							   , '3/24/2017'
							   , '18:00'
							   , '20:50'
							   , 'THU'
							   , 399;

SELECT CASE @Status
	WHEN +1 THEN '(pUpdateCourses): Update was successful'
	WHEN 0 THEN '(pUpdateCourses): No update change - error'
	WHEN -1 THEN '(pUpdateCourses): Update Failed!'
	End as [Status];

GO

DECLARE @Status INT;
EXECUTE @Status = pDeleteCourses 3;

SELECT CASE @Status
	WHEN +1 THEN '(pDeleteCourses): Delete was successful'
	WHEN 0 THEN '(pDeleteCourses): No delete change - error'
	WHEN -1 THEN '(pDeleteCourses): Delete Failed!'
	End as [Status];

--====================TEST STUDENTS====================
GO

DECLARE @Status INT;
EXECUTE @Status = pInsStudents 'Jason'
							   , 'Verberne'
							   , 'J-Verberne-012'
							   , 'JVerberne@uw.edu'
							   , '1234567890'
							   , '123 Sequal St.'
							   , ''
							   , 'Los Angeles'
							   , 'CA'
							   , '90036';

SELECT CASE @Status
	WHEN +1 THEN '(pInsStudents): Insert was successful'
	WHEN 0 THEN '(pInsStudents): No insert change - error'
	WHEN -1 THEN '(pInsStudents): Insert Failed!'
	End as [Status]

GO

DECLARE @Status INT;
EXECUTE @Status = pUpdateStudents 3
								  ,  'Jason'
								  , 'Verberne'
								  , 'J-Verberne-012'
								  , 'JVerberne@uw.edu'
								  , '1234567890'
								  , '123 Sequal St.'
								  , ''
								  , 'University Place'
								  , 'WA'
								  , '98467';

SELECT CASE @Status
	WHEN +1 THEN '(pUpdateStudents): Update was successful'
	WHEN 0 THEN '(pUpdateStudents): No update change - error'
	WHEN -1 THEN '(pUpdateStudents): Update Failed!'
	End as [Status];

GO

DECLARE @Status INT;
EXECUTE @Status = pDeleteStudents 3;

SELECT CASE @Status
	WHEN +1 THEN '(pDeleteStudents): Delete was successful'
	WHEN 0 THEN '(pDeleteStudents): No delete change - error'
	WHEN -1 THEN '(pDeleteStudents): Delete Failed!'
	End as [Status];

--====================TEST ENROLLMENTS====================
GO

DECLARE @Status INT; -- New Student for Testing Enrollments
EXECUTE @Status = pInsStudents 'Jason'
							   , 'Verberne'
							   , 'J-Verberne-012'
							   , 'JVerberne@uw.edu'
							   , '1234567890'
							   , '123 Sequal St.'
							   , ''
							   , 'Los Angeles'
							   , 'CA'
							   , '90036';

GO

DECLARE @Status INT;
EXECUTE @Status = pInsEnrollments 1
								  , 4
								  , '1/3/2017'
								  , 5000;

SELECT CASE @Status
	WHEN +1 THEN '(pInsEnrollments): Insert was successful'
	WHEN 0 THEN '(pInsEnrollments): No insert change - error'
	WHEN -1 THEN '(pInsEnrollments): Insert Failed!'
	End as [Status]

GO

DECLARE @Status INT;
EXECUTE @Status = pUpdateEnrollments 5
								  ,  1
								  , 4
								  , '1/3/2017'
								  , 12345;

SELECT CASE @Status
	WHEN +1 THEN '(pUpdateEnrollments): Update was successful'
	WHEN 0 THEN '(pUpdateEnrollments): No update change - error'
	WHEN -1 THEN '(pUpdateEnrollmentss): Update Failed!'
	End as [Status];

GO

DECLARE @Status INT;
EXECUTE @Status = pDeleteEnrollments 5;

SELECT CASE @Status
	WHEN +1 THEN '(pDeleteEnrollments): Delete was successful'
	WHEN 0 THEN '(pDeleteEnrollments): No delete change - error'
	WHEN -1 THEN '(pDeleteEnrollments): Delete Failed!'
	End as [Status];

--{ IMPORTANT!!! }--
-- To get full credit, your script must run without having to highlight individual statements!!!  
/**************************************************************************************************/


