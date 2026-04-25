USE haianhlearn_db;

DROP USER IF EXISTS 'hal_admin'@'localhost';
DROP USER IF EXISTS 'hal_staff'@'localhost';
DROP USER IF EXISTS 'hal_viewer'@'localhost';

CREATE USER 'hal_admin'@'localhost' IDENTIFIED BY 'HalAdmin@123';
CREATE USER 'hal_staff'@'localhost' IDENTIFIED BY 'HalStaff@123';
CREATE USER 'hal_viewer'@'localhost' IDENTIFIED BY 'HalViewer@123';

GRANT ALL PRIVILEGES ON haianhlearn_db.* TO 'hal_admin'@'localhost';

GRANT SELECT, INSERT, UPDATE ON haianhlearn_db.* TO 'hal_staff'@'localhost';

GRANT SELECT ON haianhlearn_db.* TO 'hal_viewer'@'localhost';

FLUSH PRIVILEGES;