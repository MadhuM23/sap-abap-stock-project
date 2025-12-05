REPORT zadd_material.

PARAMETERS:
  p_desc TYPE zmaterial_master-mat_desc OBLIGATORY,
  p_uom  TYPE zmaterial_master-ucom      OBLIGATORY.

DATA: wa_mat     TYPE zmaterial_master,
      lv_count   TYPE i,
      lv_new     TYPE zmaterial_master-mat_id,
      lv_num_str TYPE string,
      lv_desc    TYPE zmaterial_master-mat_desc.

"Check if the material description already exists
SELECT SINGLE mat_desc
  FROM zmaterial_master
  INTO lv_desc
  WHERE mat_desc = p_desc.

IF sy-subrc = 0.
  MESSAGE 'Material description already exists. Duplicate not allowed.' TYPE 'E'.
  EXIT.
ENDIF.

"Count existing materials to generate next ID
SELECT COUNT(*)
  FROM zmaterial_master
  INTO lv_count.

lv_count = lv_count + 1.

"Convert count to 3-digit number (001, 012, 123)
IF lv_count < 10.
  lv_num_str = '00' && lv_count.
ELSEIF lv_count < 100.
  lv_num_str = '0'  && lv_count.
ELSE.
  lv_num_str = |{ lv_count }|.
ENDIF.

"Creates Material ID like MAT001, MAT002
lv_new = 'MAT' && lv_num_str.

wa_mat-mat_id   = lv_new.
wa_mat-mat_desc = p_desc.
wa_mat-ucom     = p_uom.

INSERT zmaterial_master FROM wa_mat.

IF sy-subrc = 0.
  WRITE: / 'Material Added Successfully.',
         / 'Generated Material ID: ', lv_new,
         / 'Material Description:  ', p_desc,
         / 'Unit of Measure:      ', p_uom.
ELSE.
  WRITE: / 'Insert Failed.'.
ENDIF.
