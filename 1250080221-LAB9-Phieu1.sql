CREATE TABLE HANG (
    Mahang   VARCHAR2(5)   CONSTRAINT pk_hang PRIMARY KEY,
    Tenhang  VARCHAR2(50)  NOT NULL,
    Soluong  NUMBER(10),
    Giaban   NUMBER(15,2)
);
 
CREATE TABLE HOADON (
    Mahd       NUMBER        CONSTRAINT pk_hoadon PRIMARY KEY,
    Mahang     VARCHAR2(5)   REFERENCES HANG(Mahang),
    Soluongban NUMBER(10),
    Ngayban    DATE
);

INSERT INTO HANG VALUES ('H01', 'Laptop Dell',  50, 15000000);
INSERT INTO HANG VALUES ('H02', 'Chuot Logitech', 200, 250000);
INSERT INTO HANG VALUES ('H03', 'Ban phim CO',  100, 800000);
-- bài 1
CREATE OR REPLACE TRIGGER trg_hoadon_insert
BEFORE INSERT ON HOADON
FOR EACH ROW
DECLARE
    v_soluong NUMBER;
BEGIN
    -- Kiem tra Mahang co ton tai trong HANG khong
    SELECT Soluong INTO v_soluong
    FROM HANG
    WHERE Mahang = :NEW.Mahang;
    -- Kiem tra Soluongban co vuot ton kho khong
    IF :NEW.Soluongban > v_soluong THEN
        RAISE_APPLICATION_ERROR(-20001, 'Loi: So luong ban (' || :NEW.Soluongban || ') vuot qua ton kho hien tai (' || v_soluong || ')');
    END IF;
    -- Thoa man → giam ton kho
    UPDATE HANG
    SET Soluong = Soluong - :NEW.Soluongban
    WHERE Mahang = :NEW.Mahang;
 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Loi: Mahang [' || :NEW.Mahang || '] khong ton tai trong bang HANG');
END trg_hoadon_insert;
/

-- Test hop le → thanh cong, HANG.Soluong giam 3
INSERT INTO HOADON VALUES (1, 'H01', 3, SYSDATE);
-- Test Mahang khong ton tai → bao loi -20002
INSERT INTO HOADON VALUES (2, 'H99', 1, SYSDATE);
-- Test Soluongban vuot ton kho → bao loi -20001
INSERT INTO HOADON VALUES (3, 'H02', 9999, SYSDATE);
 
 --bài 2
 CREATE OR REPLACE TRIGGER trg_hoadon_delete
AFTER DELETE ON HOADON
FOR EACH ROW
BEGIN
    -- Cong lai so luong khi hoa don bi xoa
    UPDATE HANG
    SET Soluong = Soluong + :OLD.Soluongban
    WHERE Mahang = :OLD.Mahang;
END trg_hoadon_delete;
/
-- test
INSERT INTO HOADON VALUES (10, 'H01', 5, SYSDATE);
SELECT Soluong FROM HANG WHERE Mahang = 'H01';  -- giam 5
 
DELETE FROM HOADON WHERE Mahd = 10;
SELECT Soluong FROM HANG WHERE Mahang = 'H01';  -- cong lai 5
 
 -- bai 3
CREATE OR REPLACE TRIGGER trg_hoadon_update
BEFORE UPDATE ON HOADON
FOR EACH ROW
BEGIN
    -- Dieu chinh ton kho theo chenh lech so luong ban
    UPDATE HANG
    SET Soluong = Soluong - (:NEW.Soluongban - :OLD.Soluongban)
    WHERE Mahang = :NEW.Mahang;
END trg_hoadon_update;
/
 
INSERT INTO HOADON VALUES (20, 'H03', 10, SYSDATE);
SELECT Soluong FROM HANG WHERE Mahang = 'H03';  -- giam 10
 
-- Tang so luong ban tu 10 len 15 → HANG giam them 5
UPDATE HOADON SET Soluongban = 15 WHERE Mahd = 20;
SELECT Soluong FROM HANG WHERE Mahang = 'H03';  -- giam them 5

--