CREATE TABLE Patients (
PatientID INT AUTO_INCREMENT PRIMARY KEY,
Name VARCHAR(100) NOT NULL, 
Age INT NOT NULL, 
Gender ENUM('Male', 'Female', 'Other') NOT NULL,
Address VARCHAR(255), 
PhoneNumber VARCHAR(15), 
DateOfRegistration DATE NOT NULL
);


CREATE TABLE Doctors ( 
DoctorID INT AUTO_INCREMENT PRIMARY KEY, 
Name VARCHAR(100) NOT NULL,
Specialty VARCHAR(50) NOT NULL, 
Experience INT NOT NULL, 
PhoneNumber VARCHAR(15) UNIQUE
 ); 

CREATE TABLE Appointments (
AppointmentID INT AUTO_INCREMENT PRIMARY KEY,
PatientID INT,
DoctorID INT,
AppointmentDate DATE NOT NULL, 
AppointmentTime TIME NOT NULL, 
Status ENUM('Completed', 'Cancelled') DEFAULT 'Completed',
 FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
 FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID) 
);

CREATE TABLE Treatments ( 
TreatmentID INT AUTO_INCREMENT PRIMARY KEY, 
PatientID INT, DoctorID INT, 
Diagnosis VARCHAR(255), 
Prescription TEXT, 
TreatmentDate DATE NOT NULL,
 FOREIGN KEY (PatientID) REFERENCES Patients(PatientID), 
FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID) 
); 

CREATE TABLE Billing ( 
BillID INT AUTO_INCREMENT PRIMARY KEY, 
PatientID INT, 
TreatmentID INT,
 Amount DECIMAL(10, 2) NOT NULL, 
PaymentStatus ENUM('Paid', 'Pending') DEFAULT 'Pending',
 PaymentDate DATE, 
FOREIGN KEY (PatientID) REFERENCES Patients(PatientID), 
FOREIGN KEY (TreatmentID) REFERENCES Treatments(TreatmentID)
 );

—------------------------------------------------------------

*To generate 200 rows for each table, you can use MySQL Stored Procedures. Follow these steps:


DELIMITER $$
CREATE PROCEDURE PopulatePatients()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 200 DO
        INSERT INTO Patients (Name, Age, Gender, Address, PhoneNumber, DateOfRegistration)
        VALUES (
            CONCAT('Patient_', i),
            FLOOR(18 + (RAND() * 70)), -- Random age between 18 and 87
            IF(i % 2 = 0, 'Male', 'Female'),
            CONCAT('Address_', i),
            CONCAT('98765', LPAD(i, 5, '0')), -- Generates unique phone numbers
            CURDATE() - INTERVAL FLOOR(RAND() * 365) DAY
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Execute the procedure
CALL PopulatePatients();


—----------------------

DELIMITER $$
CREATE PROCEDURE PopulateDoctors()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE specialties VARCHAR(255);
    SET specialties = 'Cardiologist,Dermatologist,Orthopedic,Neurologist,Pediatrician';
    
    WHILE i <= 30 DO
        INSERT INTO Doctors (Name, Specialty, Experience, PhoneNumber)
        VALUES (
            CONCAT('Doctor_', i),
            ELT(FLOOR(1 + (RAND() * 5)), 'Cardiologist', 'Dermatologist', 'Orthopedic', 'Neurologist', 'Pediatrician'),
            FLOOR(5 + (RAND() * 30)), -- Random experience between 5 and 34 years
            CONCAT('98760', LPAD(i, 5, '0')) -- Generates unique phone numbers
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Execute the procedure
CALL PopulateDoctors();


—----------------------
DELIMITER $$
CREATE PROCEDURE PopulateAppointments()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 200 DO
        INSERT INTO Appointments (PatientID, DoctorID, AppointmentDate, AppointmentTime, Status)
        VALUES (
            FLOOR(1 + (RAND() * 200)), -- Random PatientID
            FLOOR(1 + (RAND() * 30)), -- Random DoctorID
            CURDATE() - INTERVAL FLOOR(RAND() * 180) DAY, -- Random date in the past 6 months
            TIME(FROM_UNIXTIME(FLOOR(RAND() * 86400))), -- Random time
            IF(RAND() < 0.8, 'Completed', 'Cancelled') -- 80% chance for "Completed"
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Execute the procedure
CALL PopulateAppointments();



—-----------------------------

DELIMITER $$
CREATE PROCEDURE PopulateTreatments()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 200 DO
        INSERT INTO Treatments (PatientID, DoctorID, Diagnosis, Prescription, TreatmentDate)
        VALUES (
            FLOOR(1 + (RAND() * 200)), -- Random PatientID
            FLOOR(1 + (RAND() * 30)), -- Random DoctorID
            CONCAT('Diagnosis_', FLOOR(RAND() * 100)),
            CONCAT('Prescription_', FLOOR(RAND() * 100)),
            CURDATE() - INTERVAL FLOOR(RAND() * 180) DAY
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Execute the procedure
CALL PopulateTreatments();


—--------------------------

DELIMITER $$
CREATE PROCEDURE PopulateBilling()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 200 DO
        INSERT INTO Billing (PatientID, TreatmentID, Amount, PaymentStatus, PaymentDate)
        VALUES (
            FLOOR(1 + (RAND() * 200)), -- Random PatientID
            FLOOR(1 + (RAND() * 200)), -- Random TreatmentID
            ROUND(RAND() * 950 + 50, 2), -- Random amount between 50 and 1000
            IF(RAND() < 0.7, 'Paid', 'Pending'), -- 70% chance for "Paid"
            IF(RAND() < 0.7, CURDATE() - INTERVAL FLOOR(RAND() * 180) DAY, NULL)
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

-- Execute the procedure
CALL PopulateBilling();

-- 2a.Fetch all patient details who registered in the last 30 days

select * from Patients
where DateOfRegistration >= curdate()-interval 30 day;

-- 2b.List all appointments for a specific doctor in a given date range

select * from Appointments
where DoctorID = DoctorID
  and AppointmentDate between '2024-11-01' and '2024-11-30';

-- a.Identify the doctor with the most appointments in the last month

Select name,count(a.appointmentid) as appointment_count
from doctors d join appointments a on d.doctorid=a.doctorid
where a.AppointmentDate between '2024-11-01' and '2024-11-30'
group by d.doctorID
order by appointment_count desc;

-- b.Calculate the total revenue generated by the hospital in the last quarter

select SUM(Amount) as Total_Revenue
from Billing
where PaymentDate between '2024-10-01' and '2024-12-31' and paymentstatus='paid';

-- c.Find patients who have missed or canceled more than 3 appointments

select name,COUNT(status) AS Canceledcount
from patients P join appointments a on P.Patientid=a.PatientID
where a.Status = 'Cancelled'
group by P.PatientID
having count(status) > 3;

-- a.Determine the most common diagnosis provided by each doctor

select Doctors.name,Treatments.Diagnosis,count(Treatments.Diagnosis) as DiagnosisCount
from Doctors join treatments on Doctors.DoctorID=Treatments.DoctorID
group by Doctors.DoctorID,Treatments.Diagnosis
order by Doctors.name,DiagnosisCount desc;

-- b.Analyze peak hours for appointments and suggest time slots for more efficient scheduling

select Hour(AppointmentTime) as Hour, COUNT(*) as AppointmentCount
from Appointments
group by Hour(AppointmentTime)
order by AppointmentCount desc;

-- c.Generate a monthly revenue breakdown by doctor specialty

select d.Specialty,
year(b.paymentDate) as year,
	month(b.PaymentDate) as month, 
       SUM(b.Amount) AS TotalRevenue
from Billing b
join Treatments t on b.TreatmentID = t.TreatmentID
join Doctors d on t.DoctorID = d.DoctorID
where b.PaymentStatus = 'Paid'
group by d.Specialty,year(b.paymentDate),month(b.PaymentDate)
order by d.Specialty,year,Month;
