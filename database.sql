-- UUID extension if UUID keys standard for public web APIs
CREATE EXTENSION IF NOT EXISTS "uuid_ossp";

-- Publications table
CREATE TABLE publications (
    id SERIAL PRIMARY KEY,
    doi_or_url VARCHAR(512) NOT NULL UNIQUE,
    title TEXT,
    year SMALLINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Superconductor measurements table
CREATE TABLE superconductor_entries (
    if BIGSERIAL PRIMARY KEY,
    publication_id INT NOT NULL REFERENCES publications(id) ON DELETE CASCADE, 
    material_family VARCHAR(50) NOT NULL,      -- e.g., YBCO, BSCCO, MGB2 
    material_type VARCHAR(50) NOT NULL,                 -- e.g., Thin film, Coated, Bulk 
    material_comments TEXT,             -- specific stoichiometry, doping, substrate   
    material_property VARCHAR(100),             -- standarized property name 
    property_comments TEXT,             -- exact reported value or parameter detail
    temperature_raw VARCHAR(100),               -- experimental temperature condition
    magnetic_flux_density_raw VARCHAR(100),     -- magnetic flux density condition
    raw_data_available BOOLEAN DEFAULT 0,
    additional_comments TEXT,           -- extra notes
    created_at TIMESTAMPTZ DEFAULT NOW(),   

    -- Column generation for PostgreSQL Full-Text Search (TSVECTOR)
    search_vector TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(material_family,'')), 'A') ||
        setweight(to_tsvector('english', coalesce(material_type,'')), 'B') ||
        setweight(to_tsvector('english', coalesce(measured_property,'')), 'B') ||
        setweight(to_tsvector('english', coalesce(material_comments,'')), 'C') ||
        setweight(to_tsvector('english', coalesce(additional_comments,'')), 'D')
        ) STORED
);

-- B-Tree Indexes for exact filtering & joins
CREATE INDEX idx_entries_publication_id ON superconductor_entries(publication_id);
CREATE INDEX idx_entries_material_family ON superconductor_entries(material_family);
CREATE INDEX idx_entries_material_type ON superconductor_entries(material_type);
CREATE INDEX idx_entries_measured_property ON superconductor_entries(measured_property);
CREATE INDEX idx_publications_year ON publications(year);

-- GIN Index for fast text search across superconductor attributes
CREATE INDEX idx_entries_publication_id ON superconductor_entries USING GIN(search_vector);