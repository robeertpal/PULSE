-- FUNCTII / TRIGGERS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TABELE NOMENCLATOARE (Fără dependențe mari)

CREATE TABLE counties (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    county_id INTEGER NOT NULL REFERENCES counties(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE occupations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE specializations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE interests (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE professional_grades (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE institutions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city_id INTEGER NOT NULL REFERENCES cities(id) ON DELETE RESTRICT,
    address TEXT,
    type VARCHAR(100)
);

CREATE TABLE content_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL
);


-- DOMENIUL USER

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TRIGGER update_users_modtime BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    cnp VARCHAR(13),
    phone VARCHAR(50),
    correspondence_address TEXT,
    city_id INTEGER NOT NULL REFERENCES cities(id) ON DELETE RESTRICT,
    occupation_id INTEGER NOT NULL REFERENCES occupations(id) ON DELETE RESTRICT,
    specialization_id INTEGER REFERENCES specializations(id) ON DELETE SET NULL,
    professional_grade_id INTEGER REFERENCES professional_grades(id) ON DELETE SET NULL,
    institution_id INTEGER REFERENCES institutions(id) ON DELETE SET NULL,
    total_emc_points INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TRIGGER update_user_profiles_modtime BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE user_profile_interests (
    user_profile_id INTEGER NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    interest_id INTEGER NOT NULL REFERENCES interests(id) ON DELETE CASCADE,
    PRIMARY KEY (user_profile_id, interest_id)
);


-- DOMENIUL CONTENT

CREATE TYPE content_item_type AS ENUM ('article', 'news', 'course', 'event', 'publication');

CREATE TABLE content_items (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content_type content_item_type NOT NULL,
    short_description TEXT,
    body TEXT,
    category_id INTEGER REFERENCES content_categories(id) ON DELETE SET NULL,
    specialization_id INTEGER REFERENCES specializations(id) ON DELETE SET NULL,
    hero_image_url TEXT,
    thumbnail_url TEXT,
    published_at TIMESTAMPTZ,
    author_name VARCHAR(255),
    source_url TEXT,
    is_featured BOOLEAN DEFAULT FALSE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
CREATE TRIGGER update_content_items_modtime BEFORE UPDATE ON content_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    content_item_id INTEGER UNIQUE NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    city_id INTEGER REFERENCES cities(id) ON DELETE SET NULL,
    venue_name VARCHAR(255),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    price_type VARCHAR(50) NOT NULL,
    price_amount NUMERIC(10, 2),
    emc_credits INTEGER,
    accreditation_status VARCHAR(100),
    event_page_url TEXT,
    registration_url TEXT
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    content_item_id INTEGER UNIQUE NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    emc_credits INTEGER,
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    enrollment_url TEXT,
    provider VARCHAR(255),
    course_status VARCHAR(50)
);

CREATE TABLE publications (
    id SERIAL PRIMARY KEY,
    content_item_id INTEGER UNIQUE NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    logo_url TEXT,
    description TEXT,
    emc_credits_text TEXT,
    creditation_text TEXT,
    indexing_text TEXT,
    subscription_url TEXT
);

CREATE TABLE publication_issues (
    id SERIAL PRIMARY KEY,
    publication_id INTEGER NOT NULL REFERENCES publications(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    issue_number INTEGER NOT NULL,
    issue_label VARCHAR(100),
    cover_image_url TEXT,
    description TEXT,
    published_at TIMESTAMPTZ,
    UNIQUE (publication_id, year, issue_number)
);

-- RECOMANDARI STRUCTURA (AI & Analytics)

CREATE TABLE recommendations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_item_id INTEGER NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    score NUMERIC(5, 2),
    reasoning TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (user_id, content_item_id)
);


-- TABELE DE LEGĂTURĂ / ACTIVITY LOGS / EMC (M:N User - Content Data)

CREATE TABLE saved_content (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_item_id INTEGER NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    saved_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE (user_id, content_item_id)
);

CREATE TABLE user_courses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    progress_percent INTEGER DEFAULT 0 NOT NULL,
    enrolled_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at TIMESTAMPTZ,
    status VARCHAR(50) NOT NULL,
    UNIQUE (user_id, course_id)
);

CREATE TABLE user_event_registrations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    registered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL,
    UNIQUE (user_id, event_id)
);

CREATE TABLE user_activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(100) NOT NULL,
    content_item_id INTEGER REFERENCES content_items(id) ON DELETE SET NULL,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE user_emc_point_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type VARCHAR(100) NOT NULL,
    source_id INTEGER NOT NULL,
    points INTEGER NOT NULL,
    awarded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
