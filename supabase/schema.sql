-- MediStock - Schéma Supabase
-- À exécuter dans le SQL Editor du projet Supabase (Dashboard → SQL Editor → New query → Coller → Run)

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- TABLES
-- =============================================================================

-- Foyers (familles) : un foyer = un ensemble d'utilisateurs partageant les mêmes données
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Lien utilisateur (auth) ↔ famille : qui appartient à quel foyer
CREATE TABLE family_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'member')) DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(family_id, user_id)
);

-- Membres du foyer (Papa, Maman, etc.) : profils au sein d'une famille, pour attacher les médicaments
CREATE TABLE household_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Médicaments
CREATE TABLE medications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  code_scanned TEXT NOT NULL,
  nom TEXT NOT NULL,
  quantite INTEGER NOT NULL,
  unite TEXT NOT NULL DEFAULT 'Plaquette',
  quantite_par_unite INTEGER,
  date_peremption TIMESTAMPTZ,
  lieu TEXT,
  household_member_id UUID REFERENCES household_members(id) ON DELETE SET NULL,
  seuil_alerte INTEGER NOT NULL DEFAULT 0,
  notice_url TEXT,
  photo_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Mouvements de stock
CREATE TABLE stock_movements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('ajout', 'prise')),
  quantite INTEGER NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Lieux de stockage
CREATE TABLE places (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Liste de courses
CREATE TABLE shopping_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  medication_id UUID REFERENCES medications(id) ON DELETE SET NULL,
  label TEXT NOT NULL,
  checked BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Allergies (liées à un membre du foyer)
CREATE TABLE user_allergies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  household_member_id UUID REFERENCES household_members(id) ON DELETE CASCADE,
  allergy_text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- INDEX
-- =============================================================================
CREATE INDEX idx_family_users_family ON family_users(family_id);
CREATE INDEX idx_family_users_user ON family_users(user_id);
CREATE UNIQUE INDEX idx_family_users_family_user ON family_users(family_id, user_id);

CREATE INDEX idx_household_members_family ON household_members(family_id);

CREATE INDEX idx_medications_family ON medications(family_id);
CREATE INDEX idx_medications_code ON medications(code_scanned);
CREATE INDEX idx_medications_household_member ON medications(household_member_id);

CREATE INDEX idx_stock_movements_family ON stock_movements(family_id);
CREATE INDEX idx_stock_movements_medication ON stock_movements(medication_id);

CREATE INDEX idx_places_family ON places(family_id);

CREATE INDEX idx_shopping_items_family ON shopping_items(family_id);

CREATE INDEX idx_user_allergies_family ON user_allergies(family_id);
CREATE INDEX idx_user_allergies_household_member ON user_allergies(household_member_id);

-- =============================================================================
-- TRIGGERS updated_at
-- =============================================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER medications_updated_at
  BEFORE UPDATE ON medications
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER families_updated_at
  BEFORE UPDATE ON families
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================
-- Helper : l'utilisateur courant appartient-il à cette famille ?
CREATE OR REPLACE FUNCTION user_belongs_to_family(fid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM family_users
    WHERE family_id = fid AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_allergies ENABLE ROW LEVEL SECURITY;

-- families : voir uniquement les familles dont on est membre
CREATE POLICY families_select ON families FOR SELECT
  USING (user_belongs_to_family(id));
CREATE POLICY families_insert ON families FOR INSERT
  WITH CHECK (true);
CREATE POLICY families_update ON families FOR UPDATE
  USING (user_belongs_to_family(id));
CREATE POLICY families_delete ON families FOR DELETE
  USING (user_belongs_to_family(id));

-- family_users : voir/modifier les lignes de ses familles ou sa propre ligne
CREATE POLICY family_users_select ON family_users FOR SELECT
  USING (user_id = auth.uid() OR user_belongs_to_family(family_id));
CREATE POLICY family_users_insert ON family_users FOR INSERT
  WITH CHECK (user_id = auth.uid() OR user_belongs_to_family(family_id));
CREATE POLICY family_users_update ON family_users FOR UPDATE
  USING (user_belongs_to_family(family_id));
CREATE POLICY family_users_delete ON family_users FOR DELETE
  USING (user_belongs_to_family(family_id));

-- household_members
CREATE POLICY household_members_all ON household_members
  FOR ALL USING (user_belongs_to_family(family_id));

-- medications
CREATE POLICY medications_all ON medications
  FOR ALL USING (user_belongs_to_family(family_id));

-- stock_movements
CREATE POLICY stock_movements_all ON stock_movements
  FOR ALL USING (user_belongs_to_family(family_id));

-- places
CREATE POLICY places_all ON places
  FOR ALL USING (user_belongs_to_family(family_id));

-- shopping_items
CREATE POLICY shopping_items_all ON shopping_items
  FOR ALL USING (user_belongs_to_family(family_id));

-- user_allergies
CREATE POLICY user_allergies_all ON user_allergies
  FOR ALL USING (user_belongs_to_family(family_id));
