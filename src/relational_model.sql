Relational Model as follows:

customers | CREATE TABLE `customers` (
  `cust_id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(128) NOT NULL,
  `last_name` varchar(128) NOT NULL,
  `creation_date` date NOT NULL,
  `modify_date` date NOT NULL,
  `address` varchar(1024) DEFAULT NULL,
  `address_state` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`cust_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 

stores all the customer attributes.

visit_types | CREATE TABLE `visit_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `description` varchar(256) NOT NULL,
  `creation_date` date DEFAULT NULL,
  `modify_date` date DEFAULT NULL,
  `created_by` varchar(128) DEFAULT NULL,
  `modified_by` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8

stores the various visit types (currently SITE_VISIT, IMAGE, ORDER)

customer_visits | CREATE TABLE `customer_visits` (
  `visit_id` int(11) NOT NULL AUTO_INCREMENT,
  `cust_id` int(11) NOT NULL,
  `vtype_id` int(11) NOT NULL,
  `visit_date` date DEFAULT NULL,
  `modify_date` date DEFAULT NULL,
  `created_by` varchar(128) DEFAULT NULL,
  `modified_by` varchar(128) DEFAULT NULL,
  `total_amount` decimal(13,2) DEFAULT NULL,
  PRIMARY KEY (`visit_id`),
  KEY `cust_id` (`cust_id`),
  KEY `vtype_id` (`vtype_id`),
  CONSTRAINT `customer_visits_ibfk_1` FOREIGN KEY (`cust_id`) REFERENCES `customers` (`cust_id`),
  CONSTRAINT `customer_visits_ibfk_2` FOREIGN KEY (`vtype_id`) REFERENCES `visit_types` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8

stores all customer interactions.

cust_lifetimevalue_f | CREATE TABLE `cust_lifetimevalue_f` (
  `cust_id` int(11) NOT NULL,
  `creation_date` date DEFAULT NULL,
  `created_by` varchar(128) DEFAULT NULL,
  `value` decimal(13,2) DEFAULT NULL,
  KEY `cust_id` (`cust_id`),
  CONSTRAINT `cust_lifetimevalue_f_ibfk_1` FOREIGN KEY (`cust_id`) REFERENCES `customers` (`cust_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 

Lifetime Value Fact table that will be periodically (job to run hourly, daily, weekly) truncated/populated 
based on business requirements by a job that calculates the lifetime value for each customer based on the data 
available in customer_visits table. 

SQLs to be included part of the job include
----------------------------------------------------
select min(visit_date) as start_date, max(visit_date) as end_date from customer_visits;
select floor(datediff(start_date,end_date)/7) as num_weeks;
select cust_id, (sum(total_amount)*10)/num_weeks ltv from customer_visits cv, visit_types vt 
where cv.vtype_id = vt.id and vt.name = 'ORDER' 
group by cust_id,vtype_id 
order by cust_id, ltv desc;

Alternatively a materialized view could be used to periodically updated based on updates to the customer visit table.

Seed sqls used
------------------
create table customers ( 
  cust_id int not null auto increment,  
  first_name varchar(128) not null, 
  last_name varchar(128) not null,
  creation_date date not null, 
  modify_date date not null, 
  address varchar(1024), 
  address_state varchar(2), 
  primary key (cust_id));

insert into customers (first_name,last_name,creation_date,modify_date,address,address_state) VALUES( 'Jill', 'Bondi', sysdate(), sysdate(), '1002 White House', 'AK');
insert into customers (first_name,last_name,creation_date,modify_date,address,address_state) VALUES( 'James', 'Bond', sysdate(), sysdate(), '1001 Black House', 'AL');

create table customer_visits( 
  visit_id int not null auto increment, 
  cust_id int not null, vtype_id int not null, 
  visit_date date, modify_date date, 
  created_by varchar(128), 
  modified_by varchar(128), 
  total_amount decimal(13,2), 
  primary key (visit_id), 
  foreign key(cust_id) references customers(cust_id),
  foreign key(vtype_id) references visit_types(id));

insert into customer_visits(cust_id, vtype_id, visit_date, modify_date, created_by, modified_by, total_amount) values(1, 2, sysdate(), sysdate(), "SYS", "SYS", 12.50);
insert into customer_visits(cust_id, vtype_id, visit_date, modify_date, created_by, modified_by, total_amount) values(1, 2, sysdate()-1, sysdate()-1, "SYS", "SYS", 10.50);
insert into customer_visits(cust_id, vtype_id, visit_date, modify_date, created_by, modified_by, total_amount) values(2, 3, sysdate(), sysdate(), "SYS","SYS", 191.50);
insert into customer_visits(cust_id, vtype_id, visit_date, modify_date, created_by, modified_by, total_amount) values(2, 2, sysdate(), sysdate(), "SYS","SYS", 23.50);
insert into customer_visits(cust_id, vtype_id, visit_date, modify_date, created_by, modified_by, total_amount) values(2, 2, sysdate()-1, sysdate()-1, "SYS","SYS", 32.50);


create table visit_types(
  id nt not null auto increment, 
  name varchar(64) not null, 
  description varchar(256) not null, 
  creation_date date, modify_date date, 
  created_by varchar(128), 
  modified_by varchar(128), primary key (id));
  
insert into visit_types(name, description, creation_date, modify_date, created_by, modified_by) values('SITE_VISIT', 'Customer Visit', sysdate(), sysdate(), 'SYS', 'SYS');
insert into visit_types(name, description, creation_date, modify_date, created_by, modified_by) values('ORDER', 'Customer Order', sysdate(), sysdate(), 'SYS', 'SYS');
insert into visit_types(name, description, creation_date, modify_date, created_by, modified_by) values('IMAGE', 'Customer Image', sysdate(), sysdate(), 'SYS', 'SYS');

create table cust_lifetimevalue_f(cust_id int not null, creation_date date, created_by varchar(128), value decimal(13,2), foreign key(cust_id) references customers(cust_id));

insert into cust_lifetimevalue_f(cust_id, creation_date, created_by, value) values(1, sysdate(), 'SYS', 2013);
insert into cust_lifetimevalue_f(cust_id, creation_date, created_by, value) values(2, sysdate(), 'SYS', 12012);
