-- =====================================================
-- AUTO-GENERATED QUESTIONS FROM DICTIONARY DATA
-- =====================================================

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'translation', 'Translate to English: với', 'với', 'to reach out, to reach; with, to, towards from', 1, 'với means to reach out, to reach; with, to, towards from in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'translation', 'Translate to English: là', 'là', 'fine silk; to bẹ; then; to press iron', 2, 'là means fine silk; to bẹ; then; to press iron in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'translation', 'Translate to English: tôi', 'tôi', 'subject servant self; I, me to temper, to slake', 3, 'tôi means subject servant self; I, me to temper, to slake in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'translation', 'Translate to English: đẹp', 'đẹp', 'beautiful; handsome; fair; pretty', 4, 'đẹp means beautiful; handsome; fair; pretty in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'translation', 'Translate to English: no', 'no', 'gorged; surfeited', 5, 'no means gorged; surfeited in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'translation', 'Translate to English: và', 'và', 'and', 1, 'và means and in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'translation', 'Translate to English: không', 'không', 'not; nothing; without; air', 2, 'không means not; nothing; without; air in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'translation', 'Translate to English: xấu', 'xấu', 'ugly, bad, worse', 3, 'xấu means ugly, bad, worse in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Hot Drinks'), 'translation', 'Translate to English: từ', 'từ', 'word; temple guard; from, since; to renounce, to give up', 4, 'từ means word; temple guard; from, since; to renounce, to give up in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Fruits'), 'translation', 'Translate to English: không', 'không', 'not; nothing; without; air', 1, 'không means not; nothing; without; air in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Fruits'), 'translation', 'Translate to English: cô', 'cô', 'Aunt; auntie; Miss; young lady; To boil down', 2, 'cô means Aunt; auntie; Miss; young lady; To boil down in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Fruits'), 'translation', 'Translate to English: từ', 'từ', 'word; temple guard; from, since; to renounce, to give up', 3, 'từ means word; temple guard; from, since; to renounce, to give up in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Fruits'), 'translation', 'Translate to English: xấu', 'xấu', 'ugly, bad, worse', 4, 'xấu means ugly, bad, worse in English.', 15);

-- Translation Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, vietnamese_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Fruits'), 'translation', 'Translate to English: ăn', 'ăn', 'To eat, to feed, to take, to have', 5, 'ăn means To eat, to feed, to take, to have in English.', 15);

-- Matching Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'matching', 'Match Vietnamese words with their English translations', 1, 'Connect each Vietnamese word to its correct English meaning.', 20);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'anh', true, 1, 'pair1');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Elder brother; First cousin, cousin german (son of one''s father''s or mother''s elder brother or sister)', true, 2, 'pair1');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'ăn', true, 3, 'pair2');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'To eat, to feed, to take, to have', true, 4, 'pair2');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'bàn', true, 5, 'pair3');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Table', true, 6, 'pair3');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'be', true, 7, 'pair4');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Basic Colors') AND question_order = 1), 'Wine flask; Beige; To build mud embankments on; To surround with hands top of heaped vessel (to secure the fullest measure)', true, 8, 'pair4');

-- Matching Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Family Members'), 'matching', 'Match Vietnamese words with their English translations', 1, 'Connect each Vietnamese word to its correct English meaning.', 20);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'anh', true, 1, 'pair1');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'Elder brother; First cousin, cousin german (son of one''s father''s or mother''s elder brother or sister)', true, 2, 'pair1');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'ăn', true, 3, 'pair2');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'To eat, to feed, to take, to have', true, 4, 'pair2');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'bàn', true, 5, 'pair3');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'Table', true, 6, 'pair3');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'be', true, 7, 'pair4');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'Wine flask; Beige; To build mud embankments on; To surround with hands top of heaped vessel (to secure the fullest measure)', true, 8, 'pair4');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'có', true, 9, 'pair5');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Family Members') AND question_order = 1), 'To be; To have, to own', true, 10, 'pair5');

-- Matching Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Body Parts'), 'matching', 'Match Vietnamese words with their English translations', 1, 'Connect each Vietnamese word to its correct English meaning.', 20);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Body Parts') AND question_order = 1), 'anh', true, 1, 'pair1');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Body Parts') AND question_order = 1), 'Elder brother; First cousin, cousin german (son of one''s father''s or mother''s elder brother or sister)', true, 2, 'pair1');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Body Parts') AND question_order = 1), 'ăn', true, 3, 'pair2');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Body Parts') AND question_order = 1), 'To eat, to feed, to take, to have', true, 4, 'pair2');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Body Parts') AND question_order = 1), 'bàn', true, 5, 'pair3');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Body Parts') AND question_order = 1), 'Table', true, 6, 'pair3');

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Body Parts') AND question_order = 1), 'be', true, 7, 'pair4');
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order, match_pair_id) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Body Parts') AND question_order = 1), 'Wine flask; Beige; To build mud embankments on; To surround with hands top of heaped vessel (to secure the fullest measure)', true, 8, 'pair4');

-- Fill Blank Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'fill_blank', 'The word for ''bảng chữ cái; khái niệm cơ sở, cơ sở; (ngành đường sắt) bảng chỉ đường theo abc'' in English is ______.', 'a', 1, 'The correct answer is ''a''.', 10);

-- Fill Blank Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'fill_blank', 'The word for ''A (đơn vị diện tích ruộng đất, bằng 100m2)'' in English is ______.', 'are', 2, 'The correct answer is ''are''.', 10);

-- Fill Blank Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Colors'), 'fill_blank', '''xấu, tồi, dở; ác, bất lương, xấu; có hại cho, nguy hiểm cho; nặng, trầm trọng; ươn, thiu, thối, hỏng; khó chịu; (thông tục) đồ bất lương, kẻ thành tích bất hảo, đồ vô lại; đồ đê tiện; (xem) bebt; (xem) egg; (xem) hat; thức ăn không bổ; sự mất dạy; (xem) shot; răng đau; (xem) worse; không có cái gì là hoàn toàn xấu; trong cái không may cũng có cái may; (xem) grace; vận rủi, vận không may, vận xấu; cái xấu; phá sản; sa ngã; bị thiệt, bị lỗ; còn thiếu, còn nợ'' is called ______ in English.', 'bad', 3, 'The correct answer is ''bad''.', 10);

-- Fill Blank Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Numbers'), 'fill_blank', '''bảng chữ cái; khái niệm cơ sở, cơ sở; (ngành đường sắt) bảng chỉ đường theo abc'' is called ______ in English.', 'a', 1, 'The correct answer is ''a''.', 10);

-- Fill Blank Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Numbers'), 'fill_blank', 'In English, we say ______ when we mean ''A (đơn vị diện tích ruộng đất, bằng 100m2)''.', 'are', 2, 'The correct answer is ''are''.', 10);

-- Fill Blank Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Numbers'), 'fill_blank', 'The word for ''xấu, tồi, dở; ác, bất lương, xấu; có hại cho, nguy hiểm cho; nặng, trầm trọng; ươn, thiu, thối, hỏng; khó chịu; (thông tục) đồ bất lương, kẻ thành tích bất hảo, đồ vô lại; đồ đê tiện; (xem) bebt; (xem) egg; (xem) hat; thức ăn không bổ; sự mất dạy; (xem) shot; răng đau; (xem) worse; không có cái gì là hoàn toàn xấu; trong cái không may cũng có cái may; (xem) grace; vận rủi, vận không may, vận xấu; cái xấu; phá sản; sa ngã; bị thiệt, bị lỗ; còn thiếu, còn nợ'' in English is ______.', 'bad', 3, 'The correct answer is ''bad''.', 10);

-- Fill Blank Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, correct_answer, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Numbers'), 'fill_blank', 'The word for ''thì, là; có, tồn tại, ở, sống; trở nên, trở thành; xảy ra, diễn ra; giá; be to phải, định, sẽ; (+ động tính từ hiện tại) đang; (+ động tính từ quá khứ) bị, được; đã đi, đã đến; chống lại; tán thành, đứng về phía'' in English is ______.', 'be', 4, 'The correct answer is ''be''.', 10);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "a" mean?', 1, '"a" means bảng chữ cái; khái niệm cơ sở, cơ sở; (ngành đường sắt) bảng chỉ đường theo abc.', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 1), 'bảng chữ cái; khái niệm cơ sở, cơ sở; (ngành đường sắt) bảng chỉ đường theo abc', true, 1);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 1), '(y học) viêm màng não', false, 2);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 1), 'nhau dạng đĩa', false, 3);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "are" mean?', 2, '"are" means A (đơn vị diện tích ruộng đất, bằng 100m2).', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 2), 'sự dìm xuống nước, sự nhận chìm xuống nước; sự làm ngập nước; sự lặn (tàu ngầm)', false, 2);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 2), 'Người bảo vệ đức tin (Fidei Defensor)', false, 3);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 2), 'A (đơn vị diện tích ruộng đất, bằng 100m2)', true, 1);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "bad" mean?', 3, '"bad" means xấu, tồi, dở; ác, bất lương, xấu; có hại cho, nguy hiểm cho; nặng, trầm trọng; ươn, thiu, thối, hỏng; khó chịu; (thông tục) đồ bất lương, kẻ thành tích bất hảo, đồ vô lại; đồ đê tiện; (xem) bebt; (xem) egg; (xem) hat; thức ăn không bổ; sự mất dạy; (xem) shot; răng đau; (xem) worse; không có cái gì là hoàn toàn xấu; trong cái không may cũng có cái may; (xem) grace; vận rủi, vận không may, vận xấu; cái xấu; phá sản; sa ngã; bị thiệt, bị lỗ; còn thiếu, còn nợ.', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 3), 'năn nỉ, khẩn khoản', false, 2);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 3), 'xấu, tồi, dở; ác, bất lương, xấu; có hại cho, nguy hiểm cho; nặng, trầm trọng; ươn, thiu, thối, hỏng; khó chịu; (thông tục) đồ bất lương, kẻ thành tích bất hảo, đồ vô lại; đồ đê tiện; (xem) bebt; (xem) egg; (xem) hat; thức ăn không bổ; sự mất dạy; (xem) shot; răng đau; (xem) worse; không có cái gì là hoàn toàn xấu; trong cái không may cũng có cái may; (xem) grace; vận rủi, vận không may, vận xấu; cái xấu; phá sản; sa ngã; bị thiệt, bị lỗ; còn thiếu, còn nợ', true, 1);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 3), '(giải phẫu) cơ duỗi ((cũng) extensor musicle)', false, 3);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "be" mean?', 4, '"be" means thì, là; có, tồn tại, ở, sống; trở nên, trở thành; xảy ra, diễn ra; giá; be to phải, định, sẽ; (+ động tính từ hiện tại) đang; (+ động tính từ quá khứ) bị, được; đã đi, đã đến; chống lại; tán thành, đứng về phía.', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 4), '(y học) (thuộc) bệnh uốn ván', false, 2);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 4), 'thì, là; có, tồn tại, ở, sống; trở nên, trở thành; xảy ra, diễn ra; giá; be to phải, định, sẽ; (+ động tính từ hiện tại) đang; (+ động tính từ quá khứ) bị, được; đã đi, đã đến; chống lại; tán thành, đứng về phía', true, 1);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 4), '(thuộc) ngôn ngữ, (thuộc) ngôn ngữ học', false, 3);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "big" mean?', 5, '"big" means to, lớn; bụng to, có mang, có chửa; quan trọng; hào hiệp, phóng khoáng, rộng lượng; huênh hoang, khoác lác; (từ lóng) quá tự tin, tự phụ tự mãn; làm bộ làm tịch; ra vẻ quan trọng, với vẻ quan trọng; huênh hoang khoác lác.', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 5), 'người nô lệ ((nghĩa đen) & (nghĩa bóng)); (sử học) nông nô', false, 3);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 5), 'to, lớn; bụng to, có mang, có chửa; quan trọng; hào hiệp, phóng khoáng, rộng lượng; huênh hoang, khoác lác; (từ lóng) quá tự tin, tự phụ tự mãn; làm bộ làm tịch; ra vẻ quan trọng, với vẻ quan trọng; huênh hoang khoác lác', true, 1);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 5), 'không căn cứ, vô cớ', false, 2);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "blue" mean?', 6, '"blue" means xanh; mặc quần áo xanh; (thông tục) chán nản, thất vọng; hay chữ (đàn bà); tục tĩu (câu chuyện); (chính trị) (thuộc) đảng Tô rõi rệu 1 chĩu phĩu uống say mèm, uống say bí tỉ; chửi tục; (xem) moon; màu xanh; phẩm xanh, thuốc xanh; (the blue) bầu trời; (the blue) biển cả; vận động viên điền kinh (trường đại học Ôc-phớt và Căm-brít); huy hiệu vận động điền kinh (trường đại học Ôc-phớt và Căm-brít); nữ học giả, nữ sĩ ((cũng) blue stocking); (số nhiều) sự buồn chán; (xem) bolt; hoàn toàn bất ngờ; làm xanh, nhuộm xanh; hồ lơ (quần áo); (từ lóng) xài phí, phung phí (tiền bạc).', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 6), 'xanh; mặc quần áo xanh; (thông tục) chán nản, thất vọng; hay chữ (đàn bà); tục tĩu (câu chuyện); (chính trị) (thuộc) đảng Tô rõi rệu 1 chĩu phĩu uống say mèm, uống say bí tỉ; chửi tục; (xem) moon; màu xanh; phẩm xanh, thuốc xanh; (the blue) bầu trời; (the blue) biển cả; vận động viên điền kinh (trường đại học Ôc-phớt và Căm-brít); huy hiệu vận động điền kinh (trường đại học Ôc-phớt và Căm-brít); nữ học giả, nữ sĩ ((cũng) blue stocking); (số nhiều) sự buồn chán; (xem) bolt; hoàn toàn bất ngờ; làm xanh, nhuộm xanh; hồ lơ (quần áo); (từ lóng) xài phí, phung phí (tiền bạc)', true, 1);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 6), 'từ nghiệm', false, 2);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 6), 'dây thừng (để cột ngựa vào cọc); dây thòng lọng (để bắt ngựa, bò...); bắt (ngựa, thú rừng) bằng dây thòng lọng', false, 3);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "do" mean?', 7, '"do" means làm, thực hiện; làm, làm cho, gây cho; làm, học (bài...); giải (bài toán); dịch; ((thường) thời hoàn thành & động tính từ quá khứ) làm xong, xong, hết; dọn, thu dọn, sắp xếp, thu xếp ngăn nắp, sửa soạn; nấu, nướng, quay, rán; đóng vai; làm ra vẻ, làm ra bộ; làm mệt lử, làm kiệt sức; đi, qua (một quãng đường); (từ lóng) bịp, lừa bịp, ăn gian; (thông tục) đi thăm, đi tham quan; (từ lóng) chịu (một hạn tù); (từ lóng) cho ăn, đãi; làm, thực hiện, xử sự, hành động, hoạt động; thời hoàn thành làm xong, hoàn thành, chấm dứt; được, ổn, chu toàn, an toàn, hợp; thấy trong người, thấy sức khoẻ (tốt, xấu...); làm ăn xoay sở; (dùng ở câu nghi vấn và câu phủ định); (dùng để nhấn mạnh ý khẳng định, mệnh lệnh); (dùng thay thế cho một động từ khác để tránh nhắc lại); làm lại, làm lại lần nữa; bỏ đi, huỷ bỏ, gạt bỏ, diệt đi, làm mất đi; xử sự, đối xử; chăm nom công việc gia đình cho, lo việc nội trợ cho (ai); khử đi, trừ khử, giết đi; phá huỷ, huỷ hoại đi; làm tiêu ma đi sự nghiệp, làm thất cơ lỡ vận; bắt, tóm cổ (ai); tống (ai) vào tù; rình mò theo dõi (ai); khử (ai), phăng teo (ai); làm mệt lử, làm kiệt sức; bỏ ra (mũ), cởi ra (áo); bỏ (thói quen); mặc (áo) vào; làm lại, bắt đầu lại; (+ with) trát, phết, bọc; gói, bọc; sửa lại (cái mũ, gian phòng...); làm mệt lử, làm kiệt sức, làm sụm lưng; vui lòng, vừa ý với; ổn, được, chịu được, thu xếp được, xoay sở được; bỏ được, bỏ qua được, nhin được, không cần đến; lâm chiến, đánh nhau; giết ai; (từ lóng) làm hết sức mình; giết chết; (từ lóng) bịp, lừa bịp, ăn gian; (từ lóng) phỉnh ai, tâng bốc ai; (xem) brown; được chứ! đồng ý chứ!; không ai làm những điều như thế!, điều đó không ổn đâu!; hay lắm! hoan hô!; (từ lóng) trò lừa đảo, trò lừa bịp; (thông tục) chầu, bữa chén, bữa nhậu nhẹt; (số nhiều) phần; (Uc) (từ lóng) sự tiến bộ, sự thành công; (âm nhạc) đô; (viết tắt) của ditto.', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 7), 'có nhiều dòng suối, có nhiều dòng sông nhỏ, có nhiều dòng nước; như dòng suối, như dòng sông nhỏ, như dòng nước; chảy ra, trào ra, tuôn ra, ròng ròng; (từ hiếm,nghĩa hiếm) có dáng khi động (tàu xe)', false, 3);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 7), 'làm, thực hiện; làm, làm cho, gây cho; làm, học (bài...); giải (bài toán); dịch; ((thường) thời hoàn thành & động tính từ quá khứ) làm xong, xong, hết; dọn, thu dọn, sắp xếp, thu xếp ngăn nắp, sửa soạn; nấu, nướng, quay, rán; đóng vai; làm ra vẻ, làm ra bộ; làm mệt lử, làm kiệt sức; đi, qua (một quãng đường); (từ lóng) bịp, lừa bịp, ăn gian; (thông tục) đi thăm, đi tham quan; (từ lóng) chịu (một hạn tù); (từ lóng) cho ăn, đãi; làm, thực hiện, xử sự, hành động, hoạt động; thời hoàn thành làm xong, hoàn thành, chấm dứt; được, ổn, chu toàn, an toàn, hợp; thấy trong người, thấy sức khoẻ (tốt, xấu...); làm ăn xoay sở; (dùng ở câu nghi vấn và câu phủ định); (dùng để nhấn mạnh ý khẳng định, mệnh lệnh); (dùng thay thế cho một động từ khác để tránh nhắc lại); làm lại, làm lại lần nữa; bỏ đi, huỷ bỏ, gạt bỏ, diệt đi, làm mất đi; xử sự, đối xử; chăm nom công việc gia đình cho, lo việc nội trợ cho (ai); khử đi, trừ khử, giết đi; phá huỷ, huỷ hoại đi; làm tiêu ma đi sự nghiệp, làm thất cơ lỡ vận; bắt, tóm cổ (ai); tống (ai) vào tù; rình mò theo dõi (ai); khử (ai), phăng teo (ai); làm mệt lử, làm kiệt sức; bỏ ra (mũ), cởi ra (áo); bỏ (thói quen); mặc (áo) vào; làm lại, bắt đầu lại; (+ with) trát, phết, bọc; gói, bọc; sửa lại (cái mũ, gian phòng...); làm mệt lử, làm kiệt sức, làm sụm lưng; vui lòng, vừa ý với; ổn, được, chịu được, thu xếp được, xoay sở được; bỏ được, bỏ qua được, nhin được, không cần đến; lâm chiến, đánh nhau; giết ai; (từ lóng) làm hết sức mình; giết chết; (từ lóng) bịp, lừa bịp, ăn gian; (từ lóng) phỉnh ai, tâng bốc ai; (xem) brown; được chứ! đồng ý chứ!; không ai làm những điều như thế!, điều đó không ổn đâu!; hay lắm! hoan hô!; (từ lóng) trò lừa đảo, trò lừa bịp; (thông tục) chầu, bữa chén, bữa nhậu nhẹt; (số nhiều) phần; (Uc) (từ lóng) sự tiến bộ, sự thành công; (âm nhạc) đô; (viết tắt) của ditto', true, 1);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 7), 'công việc trí óc', false, 2);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "food" mean?', 8, '"food" means đồ ăn, thức ăn, món ăn; (định ngữ) dinh dưỡng; làm cho suy nghĩ; chết đuối, làm mồi cho cá; chết, đi ngủ với giun; (xem) powder.', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 8), 'đồ ăn, thức ăn, món ăn; (định ngữ) dinh dưỡng; làm cho suy nghĩ; chết đuối, làm mồi cho cá; chết, đi ngủ với giun; (xem) powder', true, 1);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 8), 'đạo sĩ, pháp sư, thầy phù thuỷ; nhà bác học, nhà thông thái', false, 2);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 8), 'áo gi lê', false, 3);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "good" mean?', 9, '"good" means tốt, hay, tuyệt; tử tế, rộng lượng, thương người; có đức hạnh, ngoan; tươi (cá); tốt lành, trong lành, lành; có lợi; cừ, giỏi, đảm đang, được việc; vui vẻ, dễ chịu, thoải mái; được hưởng một thời gian vui thích; hoàn toàn, triệt để; ra trò, nên thân; đúng, phải; tin cậy được; an toàn, chắc chắn; có giá trị; khoẻ, khoẻ mạnh, đủ sức; thân, nhà (dùng trong câu gọi); khá nhiều, khá lớn, khá xa; ít nhất là; hầu như, coi như, gần như; giúp đỡ (ai); rất tốt, rất ngoan; (từ Mỹ,nghĩa Mỹ) rất tốt, rất xứng đáng, rất thích hợp; chào (trong ngày); tạm biệt nhé!; chào (buổi sáng); chào (buổi chiều); chào (buổi tối); chúc ngủ ngon, tạm biệt nhé!; chúc may mắn; (thông tục) lương cao; có ý muốn làm cái gì; vui vẻ, phấn khởi, phấn chấn; thực hiện; giữ (lời hứa); giữ lời hứa, làm đúng như lời hứa; bù đắp lại; gỡ lại, đền, thay; sửa chữa; xác nhận, chứng thực; (từ Mỹ,nghĩa Mỹ) làm ăn phát đạt, thành công, tiến bộ; vẫn còn giá trị; vẫn đúng; (xem) part; (từ lóng) nói dối nghe được đấy! nói láo nghe được đấy!; các vị tiên; điều thiện, điều tốt, điều lành; lợi, lợi ích; điều đáng mong muốn, vật đáng mong muốn; những người tốt, những người có đạo đức; đang rắp tâm dở trò ma mãnh gì; không đi đến đâu, không đạt kết quả gì, không làm nên trò trống gì; mãi mãi, vĩnh viễn; được lâi, được lời.', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 9), 'hoàn toàn; trọn vẹn; triệt để, không nhân nhượng', false, 2);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 9), '(thuộc) vua, (thuộc) quốc vương; (thuộc) chế độ quân ch', false, 3);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 9), 'tốt, hay, tuyệt; tử tế, rộng lượng, thương người; có đức hạnh, ngoan; tươi (cá); tốt lành, trong lành, lành; có lợi; cừ, giỏi, đảm đang, được việc; vui vẻ, dễ chịu, thoải mái; được hưởng một thời gian vui thích; hoàn toàn, triệt để; ra trò, nên thân; đúng, phải; tin cậy được; an toàn, chắc chắn; có giá trị; khoẻ, khoẻ mạnh, đủ sức; thân, nhà (dùng trong câu gọi); khá nhiều, khá lớn, khá xa; ít nhất là; hầu như, coi như, gần như; giúp đỡ (ai); rất tốt, rất ngoan; (từ Mỹ,nghĩa Mỹ) rất tốt, rất xứng đáng, rất thích hợp; chào (trong ngày); tạm biệt nhé!; chào (buổi sáng); chào (buổi chiều); chào (buổi tối); chúc ngủ ngon, tạm biệt nhé!; chúc may mắn; (thông tục) lương cao; có ý muốn làm cái gì; vui vẻ, phấn khởi, phấn chấn; thực hiện; giữ (lời hứa); giữ lời hứa, làm đúng như lời hứa; bù đắp lại; gỡ lại, đền, thay; sửa chữa; xác nhận, chứng thực; (từ Mỹ,nghĩa Mỹ) làm ăn phát đạt, thành công, tiến bộ; vẫn còn giá trị; vẫn đúng; (xem) part; (từ lóng) nói dối nghe được đấy! nói láo nghe được đấy!; các vị tiên; điều thiện, điều tốt, điều lành; lợi, lợi ích; điều đáng mong muốn, vật đáng mong muốn; những người tốt, những người có đạo đức; đang rắp tâm dở trò ma mãnh gì; không đi đến đâu, không đạt kết quả gì, không làm nên trò trống gì; mãi mãi, vĩnh viễn; được lâi, được lời', true, 1);

-- Multiple Choice Question
INSERT INTO lesson_questions (lesson_id, question_type, question_text, question_order, explanation, points) VALUES
((SELECT id FROM lessons WHERE title = 'Vocabulary Practice'), 'multiple_choice', 'What does "green" mean?', 10, '"green" means xanh lá cây, (màu) lục; xanh; tươi; đầy sức sống; thanh xuân; chưa có kinh nghiệm, mới vào nghề; thơ ngây, cả tin; tái xanh, tái ngắt (nước da); (nghĩa bóng) ghen, ghen tức, ghen tị; còn mới, chưa lành, chưa liền (vết thương); màu xanh lá cây, màu xanh lục; quần áo màu lục; phẩm lục (để nhuộm); cây cỏ; bãi cỏ xanh, thảm cỏ xanh; (số nhiều) rau; (nghĩa bóng) tuổi xanh, tuổi thanh xuân; sức sống, sức cường tráng; vẻ cả tin; vẻ ngây thơ non nớt; trở nên xanh lá cây, hoá thành màu lục; (từ lóng) bịp, lừa bịp.', 10);

INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 10), 'bin); (kỹ thuật) hố tro, máng tro, hộp tro (ở xe lửa)', false, 2);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 10), 'xanh lá cây, (màu) lục; xanh; tươi; đầy sức sống; thanh xuân; chưa có kinh nghiệm, mới vào nghề; thơ ngây, cả tin; tái xanh, tái ngắt (nước da); (nghĩa bóng) ghen, ghen tức, ghen tị; còn mới, chưa lành, chưa liền (vết thương); màu xanh lá cây, màu xanh lục; quần áo màu lục; phẩm lục (để nhuộm); cây cỏ; bãi cỏ xanh, thảm cỏ xanh; (số nhiều) rau; (nghĩa bóng) tuổi xanh, tuổi thanh xuân; sức sống, sức cường tráng; vẻ cả tin; vẻ ngây thơ non nớt; trở nên xanh lá cây, hoá thành màu lục; (từ lóng) bịp, lừa bịp', true, 1);
INSERT INTO lesson_options (question_id, option_text, is_correct, option_order) VALUES
((SELECT id FROM lesson_questions WHERE lesson_id = (SELECT id FROM lessons WHERE title = 'Vocabulary Practice') AND question_order = 10), '(y học) chứng tràn dịch ngực', false, 3);

COMMIT;
