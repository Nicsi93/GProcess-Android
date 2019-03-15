CREATE OR REPLACE FUNCTION securedSGRead(user_id VARCHAR, psg_id VARCHAR) 
RETURNS TABLE(
    r_sg_id CHAR(100),
    r_members TEXT[],
	r_create_p INT,
	r_read_p INT,
	r_update_p INT,
	r_delete_p INT,
	r_superficial_read_p INT
	

) AS $$


DECLARE 

	sg_groups VARCHAR[10];
	cur_sg VARCHAR;
	cur_members VARCHAR[10];
	cur_member VARCHAR;
	priorities INT[10];
	cur_priority INT;

BEGIN

	SELECT security_groups INTO sg_groups FROM RealmObject WHERE ro_id = psg_id;
	FOREACH cur_sg in ARRAY sg_groups
	LOOP
		SELECT members INTO cur_members FROM SecurityGroup WHERE sg_id = cur_sg;
		LOOP
			FOREACH cur_member in ARRAY cur_members
			LOOP
				IF cur_member = user_id THEN
					SELECT priority INTO cur_priority FROM Permissions WHERE p_id = 
					(SELECT read_p FROM SecurityGroup WHERE sg_id = cur_sg);
					SELECT array_append(priorities, cur_priority);
				END IF;	
			END LOOP;
		END LOOP;
	END LOOP;
	
	cur_priority = array_lower(priorities);
	
	CASE cur_priority
		WHEN 1 OR 3 THEN
	
			RETURN QUERY SELECT *
			FROM
			SecurityGroup
			WHERE
			sg_id = psg_id;
		WHEN 2 THEN
			RAISE EXCEPTION 'Forbidden';
		WHEN 4 THEN
			RAISE EXCEPTION 'None';
		WHEN 5 THEN
			RAISE EXCEPTION 'Undefined';
		WHEN 6 THEN
			RAISE EXCEPTION 'Unrelated';
	
	END CASE;
	
	
END; $$
LANGUAGE 'plpgsql';
