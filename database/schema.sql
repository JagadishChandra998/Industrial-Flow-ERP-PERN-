
CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) NOT NULL
        CHECK (role IN ('ADMIN', 'SALES_USER')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_code VARCHAR(30) UNIQUE NOT NULL,
    company_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(150),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    gst_number VARCHAR(20) UNIQUE,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
    CONSTRAINT fk_customer_creator
        FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE RESTRICT
);


CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_code VARCHAR(30) UNIQUE NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    unit VARCHAR(30) NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    gst_percentage NUMERIC(5,2) DEFAULT 0 CHECK (gst_percentage >= 0 AND gst_percentage <= 100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE inventory (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT UNIQUE NOT NULL,
    physical_quantity INTEGER NOT NULL DEFAULT 0 CHECK (physical_quantity >= 0),
    reserved_quantity INTEGER NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
    location VARCHAR(100) DEFAULT 'Main Warehouse',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_reserved_stock
        CHECK (reserved_quantity <= physical_quantity)
);


CREATE TABLE enquiries 
	(
		id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
		enquiry_number VARCHAR (30) UNIQUE NOT NULL,
		
		customer_id  BIGINT NOT NULL,
		created_by BIGINT NOT NULL,

		enquiry_date DATE DEFAULT CURRENT_DATE,
    required_date DATE NOT NULL,

    status VARCHAR(20) DEFAULT 'NEW'
        CHECK (status IN (
            'NEW',
            'IN_PROGRESS',
            'QUOTED',
            'CANCELLED'
        )),


		notes TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

		    CONSTRAINT fk_enquiry_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(id),

    CONSTRAINT fk_enquiry_creator
        FOREIGN KEY (created_by)
        REFERENCES users(id)
		
	);
	

create table enquiry_items
	(
		id bigint generated always as identity primary key,
		enquiry_id bigint not null,
		product_id bigint not null,
		quantity integer not null check (quantity > 0),
		notes text,

		created_at timestamp default current_timestamp,

		constraint fk_enquiry_item_enquiry
			foreign key (enquiry_id)
			references enquiries (id)
			on delete cascade,

		constraint fk_enquiry_item_product
			foreign key (product_id)
			references products(id)
			on delete restrict,

		constraint unique_enquiry_product
			unique (enquiry_id, product_id)
	);

-- select * from enquiry_items;

create table quotations
	(
		id bigint generated always as identity primary key,
		quotation_number varchar (30) unique not null,

		enquiry_id bigint not null,
		created_by bigint not null,

		quotation_date date default current_date,
		valid_unitl date,

		status varchar (20) default 'DRAFT'
			check(status in(
				'DRAFT',
				'SEND',
				'ACCEPTED',
				'REJECTED',
				'EXPIRED'
			)),

	   subTotal numeric(14,2) default 0 check( subTotal >= 0),
	   discount_amount numeric (14,2) default 0 check(discount_amount >= 0),
	   tax_amount numeric (14,2) default 0 check(tax_amount >=0),
	   total_amount numeric (14,2) default 0 check(total_amount >=0),

	   notes text,

	   created_at timestamp default current_timestamp,
	   updated_at timestamp default current_timestamp,

	   constraint fk_quotation_enquiry
	   	foreign key (enquiry_id)
		references enquiries(id),

		constraint fk_quotation_creator
		 foreign key (created_by)
		 references users(id)
	);

-- SELECT * FROM quotations;

create Table quotation_items (
	id bigint generated always as identity primary key,

	quotation_id bigint not null,
	product_id bigint not null,

	quantity integer not null check( quantity >= 0),
	unit_price numeric(12,2) not null check (unit_price >= 0),

	gst_percentage numeric (5,2) default 0
		check (gst_percentage between 0 and 100),

	discount_amount numeric (12,2) default 0 check (discount_amount >= 0),
	line_total NUMERIC(14,2) NOT NULL CHECK (line_total >= 0),

	created_at timestamp default current_timestamp,

	constraint fk_quotation_item_quotation
		foreign key (quotation_id)
		references quotations(id)
		on delete cascade,

	constraint fk_quotation_item_produuct
		foreign key (product_id)
		references products(id),

	constraint unique_quotation_product
		unique (quotation_id, product_id)

);
select * from quotation_items

CREATE TABLE sales_orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    sales_order_number VARCHAR(30) UNIQUE NOT NULL,

    quotation_id BIGINT NOT NULL UNIQUE,

    created_by BIGINT NOT NULL,
    confirmed_by BIGINT,

    order_date DATE DEFAULT CURRENT_DATE,

    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING','CONFIRMED','CANCELLED','COMPLETED')),

    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0
        CHECK (total_amount >= 0),

    notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sales_order_quotation
        FOREIGN KEY (quotation_id)
        REFERENCES public.quotations(id),

    CONSTRAINT fk_sales_order_creator
        FOREIGN KEY (created_by)
        REFERENCES public.users(id),

    CONSTRAINT fk_sales_order_confirmer
        FOREIGN KEY (confirmed_by)
        REFERENCES public.users(id)
);


CREATE TABLE public.sales_order_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    sales_order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,

    quantity INTEGER NOT NULL CHECK (quantity > 0),

    unit_price NUMERIC(12,2) NOT NULL
        CHECK (unit_price >= 0),

    gst_percentage NUMERIC(5,2) DEFAULT 0
        CHECK (gst_percentage BETWEEN 0 AND 100),

    line_total NUMERIC(14,2) NOT NULL
        CHECK (line_total >= 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sales_order_item_order
        FOREIGN KEY (sales_order_id)
        REFERENCES public.sales_orders(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_sales_order_item_product
        FOREIGN KEY (product_id)
        REFERENCES public.products(id),

    CONSTRAINT unique_sales_order_product
        UNIQUE (sales_order_id, product_id)
);


CREATE TABLE public.dispatches (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dispatch_number VARCHAR(30) UNIQUE NOT NULL,

    sales_order_id BIGINT NOT NULL UNIQUE,

    dispatched_by BIGINT NOT NULL,

    dispatch_date DATE DEFAULT CURRENT_DATE,

    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'DISPATCHED', 'CANCELLED')),

    tracking_number VARCHAR(100),
    vehicle_number VARCHAR(50),
    notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dispatch_sales_order
        FOREIGN KEY (sales_order_id)
        REFERENCES public.sales_orders(id),

    CONSTRAINT fk_dispatch_user
        FOREIGN KEY (dispatched_by)
        REFERENCES public.users(id)
);


CREATE TABLE public.dispatch_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    dispatch_id BIGINT NOT NULL,
    sales_order_item_id BIGINT NOT NULL,

    dispatched_quantity INTEGER NOT NULL
        CHECK (dispatched_quantity > 0),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dispatch_item_dispatch
        FOREIGN KEY (dispatch_id)
        REFERENCES public.dispatches(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_dispatch_item_order_item
        FOREIGN KEY (sales_order_item_id)
        REFERENCES public.sales_order_items(id),

    CONSTRAINT unique_dispatch_order_item
        UNIQUE (dispatch_id, sales_order_item_id)
);