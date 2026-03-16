CREATE TABLE Mathang (
    Mahang  VARCHAR2(5)  CONSTRAINT pk_mathang PRIMARY KEY,
    Tenhang VARCHAR2(50) NOT NULL,
    Soluong NUMBER(10)
);
 
CREATE TABLE Nhatkybanhang (
    Stt      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Ngay     DATE,
    Nguoimua VARCHAR2(50),
    Mahang   VARCHAR2(5)   REFERENCES Mathang(Mahang),
    Soluong  NUMBER(10),
    Giaban   NUMBER(15,2)
);

INSERT INTO Mathang VALUES ('1', 'Hang A', 100);
INSERT INTO Mathang VALUES ('2', 'Hang B', 200);
INSERT INTO Mathang VALUES ('3', 'Hang C', 150);

-- a. Trigger trg_nhatkybanhang_insert
CREATE OR REPLACE TRIGGER trg_nhatkybanhang_insert
AFTER INSERT ON Nhatkybanhang
FOR EACH ROW
BEGIN
    UPDATE Mathang
    SET Soluong = Soluong - :NEW.Soluong
    WHERE Mahang = :NEW.Mahang;
END trg_nhatkybanhang_insert;
/

INSERT INTO Nhatkybanhang(Ngay, Nguoimua, Mahang, Soluong, Giaban)
    VALUES (SYSDATE, 'Nguyen A', '1', 10, 50000);
SELECT Soluong FROM Mathang WHERE Mahang = '1';  

-- b. Trigger trg_nhatkybanhang_update_soluong
CREATE OR REPLACE TRIGGER trg_nhatkybanhang_update_soluong
AFTER UPDATE OF Soluong ON Nhatkybanhang
FOR EACH ROW
BEGIN
    UPDATE Mathang
    SET Soluong = Soluong - (:NEW.Soluong - :OLD.Soluong)
    WHERE Mahang = :NEW.Mahang;
END trg_nhatkybanhang_update_soluong;
/
-- Tang so luong tu 10 len 15 → Mathang giam them 5
UPDATE Nhatkybanhang SET Soluong = 15 WHERE Stt = 1;
SELECT Soluong FROM Mathang WHERE Mahang = '1';

-- c. Trigger BEFORE INSERT kiem tra so luong hop le
DROP TRIGGER trg_nhatkybanhang_insert;
 
CREATE OR REPLACE TRIGGER trg_nhatkybanhang_check_insert
BEFORE INSERT ON Nhatkybanhang
FOR EACH ROW
DECLARE
    v_soluong NUMBER;
BEGIN
    -- Lay ton kho hien tai
    SELECT Soluong INTO v_soluong
    FROM Mathang
    WHERE Mahang = :NEW.Mahang;
 
    -- Kiem tra so luong ban co vuot ton kho khong
    IF :NEW.Soluong > v_soluong THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Loi: So luong ban (' || :NEW.Soluong ||
            ') vuot ton kho (' || v_soluong || ')');
    END IF;
 
    -- Giam ton kho
    UPDATE Mathang
    SET Soluong = Soluong - :NEW.Soluong
    WHERE Mahang = :NEW.Mahang;
 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Loi: Mahang [' || :NEW.Mahang || '] khong ton tai');
END trg_nhatkybanhang_check_insert;
/
-- test
INSERT INTO Nhatkybanhang(Ngay, Nguoimua, Mahang, Soluong, Giaban)
    VALUES (SYSDATE, 'Tran B', '2', 20, 30000);
SELECT Soluong FROM Mathang WHERE Mahang = '2';  
-- Vuot ton kho → loi -20001
INSERT INTO Nhatkybanhang(Ngay, Nguoimua, Mahang, Soluong, Giaban)
    VALUES (SYSDATE, 'Le C', '2', 99999, 30000);
-- Mahang khong ton tai → loi -20002
INSERT INTO Nhatkybanhang(Ngay, Nguoimua, Mahang, Soluong, Giaban)
    VALUES (SYSDATE, 'Pham D', '9', 5, 10000);
    
-- d. Trigger UPDATE kiem soat so dong (Compound Trigger)
CREATE OR REPLACE PACKAGE pkg_update_state AS
    g_row_count NUMBER := 0;
END pkg_update_state;
/
 
-- Xoa trigger (b) truoc de tranh xung dot
DROP TRIGGER trg_nhatkybanhang_update_soluong;
 
CREATE OR REPLACE TRIGGER trg_nhatkybanhang_update_compound
FOR UPDATE ON Nhatkybanhang
COMPOUND TRIGGER
 
    -- Reset dem truoc khi cau lenh bat dau
    BEFORE STATEMENT IS
    BEGIN
        pkg_update_state.g_row_count := 0;
    END BEFORE STATEMENT;
 
    -- Dem va kiem tra cho tung dong
    BEFORE EACH ROW IS
    BEGIN
        pkg_update_state.g_row_count := pkg_update_state.g_row_count + 1;
        IF pkg_update_state.g_row_count > 1 THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Loi: Chi duoc phep cap nhat 1 ban ghi moi lan');
        END IF;
    END BEFORE EACH ROW;
 
    -- Cap nhat MATHANG sau khi tung dong duoc update
    AFTER EACH ROW IS
    BEGIN
        UPDATE Mathang
        SET Soluong = Soluong - (:NEW.Soluong - :OLD.Soluong)
        WHERE Mahang = :NEW.Mahang;
    END AFTER EACH ROW;
 
END trg_nhatkybanhang_update_compound;
/

UPDATE Nhatkybanhang SET Soluong = 25 WHERE Stt = 2;
SELECT Soluong FROM Mathang WHERE Mahang = '2';
 
-- Test 2: update nhieu dong → loi -20001
UPDATE Nhatkybanhang SET Soluong = 5 WHERE Mahang = '1';

-- e. Trigger DELETE kiem soat so dong (Compound Trigger)
CREATE OR REPLACE PACKAGE pkg_delete_state AS
    g_row_count NUMBER := 0;
END pkg_delete_state;
/
 
CREATE OR REPLACE TRIGGER trg_nhatkybanhang_delete_compound
FOR DELETE ON Nhatkybanhang
COMPOUND TRIGGER
 
    BEFORE STATEMENT IS
    BEGIN
        pkg_delete_state.g_row_count := 0;
    END BEFORE STATEMENT;
 
    BEFORE EACH ROW IS
    BEGIN
        pkg_delete_state.g_row_count := pkg_delete_state.g_row_count + 1;
        IF pkg_delete_state.g_row_count > 1 THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Loi: Chi duoc phep xoa 1 ban ghi moi lan');
        END IF;
    END BEFORE EACH ROW;
 
    AFTER EACH ROW IS
    BEGIN
        UPDATE Mathang
        SET Soluong = Soluong + :OLD.Soluong
        WHERE Mahang = :OLD.Mahang;
    END AFTER EACH ROW;
 
END trg_nhatkybanhang_delete_compound;
/
-- test e:
SELECT Stt, Mahang, Soluong FROM Nhatkybanhang;
 
-- Test: xoa 1 dong → thanh cong, MATHANG duoc cong lai
DELETE FROM Nhatkybanhang WHERE Stt = 1;

-- f. Trigger UPDATE nang cao – Kiem tra nhieu dieu kien

CREATE OR REPLACE PACKAGE pkg_update_adv AS
    g_row_count NUMBER := 0;
END pkg_update_adv;
/
 
CREATE OR REPLACE TRIGGER trg_nhatkybanhang_update_nangcao
FOR UPDATE ON Nhatkybanhang
COMPOUND TRIGGER
 
    BEFORE STATEMENT IS
    BEGIN
        pkg_update_adv.g_row_count := 0;
    END BEFORE STATEMENT;
 
    BEFORE EACH ROW IS
        v_sl_mathang NUMBER;
    BEGIN
        -- Kiem tra so dong
        pkg_update_adv.g_row_count := pkg_update_adv.g_row_count + 1;
        IF pkg_update_adv.g_row_count > 1 THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Loi: Chi duoc cap nhat 1 ban ghi moi lan');
        END IF;
 
        -- Lay ton kho hien tai cua mat hang
        SELECT Soluong INTO v_sl_mathang
        FROM Mathang WHERE Mahang = :NEW.Mahang;
 
        -- Kiem tra dieu kien so luong moi
        IF :NEW.Soluong < v_sl_mathang THEN
            RAISE_APPLICATION_ERROR(-20002,
                'Loi: So luong ban moi (' || :NEW.Soluong ||
                ') nho hon ton kho (' || v_sl_mathang || ')');
        ELSIF :NEW.Soluong = :OLD.Soluong THEN
            RAISE_APPLICATION_ERROR(-20003,
                'Thong bao: So luong khong thay doi, khong can cap nhat');
        END IF;
 
        -- Dieu chinh MATHANG
        UPDATE Mathang
        SET Soluong = Soluong - (:NEW.Soluong - :OLD.Soluong)
        WHERE Mahang = :NEW.Mahang;
 
    END BEFORE EACH ROW;
 
END trg_nhatkybanhang_update_nangcao;
/

-- test f
SELECT Stt, Mahang, Soluong FROM Nhatkybanhang ORDER BY Stt;
SELECT Mahang, Soluong FROM Mathang;

UPDATE Nhatkybanhang SET Soluong = 30 WHERE Stt = 2;

-- g. Thu tuc xoa MATHANG (co tac dong 2 bang)
CREATE OR REPLACE PROCEDURE proc_XoaMatHang (
    p_mahang IN Mathang.Mahang%TYPE
) AS
    v_count NUMBER;
BEGIN
    -- Kiem tra Mahang co ton tai khong
    SELECT COUNT(*) INTO v_count
    FROM Mathang
    WHERE Mahang = p_mahang;
 
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE(
            'Thong bao: Mahang [' || p_mahang || '] khong ton tai trong he thong');
    ELSE
        -- Xoa du lieu lien quan trong Nhatkybanhang truoc
        DELETE FROM Nhatkybanhang WHERE Mahang = p_mahang;
 
        -- Xoa khoi Mathang
        DELETE FROM Mathang WHERE Mahang = p_mahang;
 
        COMMIT;
        DBMS_OUTPUT.PUT_LINE(
            'Thanh cong: Da xoa Mahang [' || p_mahang || '] va cac ban ghi lien quan');
    END IF;
END proc_XoaMatHang;
/

-- h. Ham tinh tong tien theo ten hang
CREATE OR REPLACE FUNCTION fn_TongTien (
    p_tenhang IN Mathang.Tenhang%TYPE
) RETURN NUMBER AS
    v_tong NUMBER := 0;
BEGIN
    SELECT NVL(SUM(nk.Soluong * nk.Giaban), 0) INTO v_tong
    FROM Nhatkybanhang nk
    JOIN Mathang mh ON nk.Mahang = mh.Mahang
    WHERE mh.Tenhang = p_tenhang;
 
    RETURN v_tong;
END fn_TongTien;
/

-- TEST h:
INSERT INTO Nhatkybanhang(Ngay, Nguoimua, Mahang, Soluong, Giaban)
    VALUES (SYSDATE, 'Hoang E', '1', 5, 50000);
INSERT INTO Nhatkybanhang(Ngay, Nguoimua, Mahang, Soluong, Giaban)
    VALUES (SYSDATE, 'Pham F', '1', 10, 55000);
COMMIT;
 
SELECT fn_TongTien('Hang A') AS TongTien_HangA FROM DUAL;
SELECT fn_TongTien('Hang B') AS TongTien_HangB FROM DUAL;
SELECT fn_TongTien('Khong co') AS TongTien_KhongCo FROM DUAL; 