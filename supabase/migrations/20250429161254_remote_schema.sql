create type "public"."color_source" as enum ('99COLORS_NET', 'ART_PAINTS_YG07S', 'BYRNE', 'CRAYOLA', 'CMYK_COLOR_MODEL', 'COLORCODE_IS', 'COLORHEXA', 'COLORXS', 'CORNELL_UNIVERSITY', 'COLUMBIA_UNIVERSITY', 'DUKE_UNIVERSITY', 'ENCYCOLORPEDIA_COM', 'ETON_COLLEGE', 'FANTETTI_AND_PETRACCHI', 'FINDTHEDATA_COM', 'FERRARIO_1919', 'FEDERAL_STANDARD_595', 'FLAG_OF_INDIA', 'FLAG_OF_SOUTH_AFRICA', 'GLAZEBROOK_AND_BALDRY', 'GOOGLE', 'HEXCOLOR_CO', 'ISCC_NBS', 'KELLY_MOORE', 'MATTEL', 'MAERZ_AND_PAUL', 'MILK_PAINT', 'MUNSELL_COLOR_WHEEL', 'NATURAL_COLOR_SYSTEM', 'PANTONE', 'PLOCHERE', 'POURPRE_COM', 'RAL', 'RESENE', 'RGB_COLOR_MODEL', 'THOM_POOLE', 'UNIVERSITY_OF_ALABAMA', 'UNIVERSITY_OF_CALIFORNIA_DAVIS', 'UNIVERSITY_OF_CAMBRIDGE', 'UNIVERSITY_OF_NORTH_CAROLINA', 'UNIVERSITY_OF_TEXAS_AT_AUSTIN', 'X11_WEB', 'XONA_COM');

drop trigger if exists "set_updated_at" on "public"."clothing_items";

drop trigger if exists "update_free_items_used" on "public"."clothing_items";

drop policy "Users can view own api usage" on "public"."api_usage";

drop policy "Users can update own profile" on "public"."user_profiles";

drop policy "Users can view own profile" on "public"."user_profiles";

drop policy "Users can delete own items" on "public"."clothing_items";

drop policy "Users can insert own items" on "public"."clothing_items";

drop policy "Users can update own items" on "public"."clothing_items";

drop policy "Users can view own items" on "public"."clothing_items";

revoke delete on table "public"."user_profiles" from "anon";

revoke insert on table "public"."user_profiles" from "anon";

revoke references on table "public"."user_profiles" from "anon";

revoke select on table "public"."user_profiles" from "anon";

revoke trigger on table "public"."user_profiles" from "anon";

revoke truncate on table "public"."user_profiles" from "anon";

revoke update on table "public"."user_profiles" from "anon";

revoke delete on table "public"."user_profiles" from "authenticated";

revoke insert on table "public"."user_profiles" from "authenticated";

revoke references on table "public"."user_profiles" from "authenticated";

revoke select on table "public"."user_profiles" from "authenticated";

revoke trigger on table "public"."user_profiles" from "authenticated";

revoke truncate on table "public"."user_profiles" from "authenticated";

revoke update on table "public"."user_profiles" from "authenticated";

revoke delete on table "public"."user_profiles" from "service_role";

revoke insert on table "public"."user_profiles" from "service_role";

revoke references on table "public"."user_profiles" from "service_role";

revoke select on table "public"."user_profiles" from "service_role";

revoke trigger on table "public"."user_profiles" from "service_role";

revoke truncate on table "public"."user_profiles" from "service_role";

revoke update on table "public"."user_profiles" from "service_role";

alter table "public"."user_profiles" drop constraint "user_profiles_id_fkey";

alter table "public"."user_profiles" drop constraint "valid_role";

alter table "public"."api_usage" drop constraint "api_usage_user_id_fkey";

alter table "public"."clothing_items" drop constraint "clothing_items_user_id_fkey";

drop function if exists "public"."handle_new_user"();

drop function if exists "public"."handle_updated_at"();

drop function if exists "public"."increment_free_items_used"(user_id uuid);

drop function if exists "public"."set_user_as_admin"(user_id uuid);

drop function if exists "public"."update_free_items_count"();

drop function if exists "public"."update_subscription_status"();

alter table "public"."user_profiles" drop constraint "user_profiles_pkey";

drop index if exists "public"."user_profiles_pkey";

drop table "public"."user_profiles";

create table "public"."api_costs" (
    "id" bigint generated always as identity not null,
    "user_id" uuid not null,
    "total_cost" double precision not null,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now())
);


create table "public"."outfit_combinations" (
    "id" uuid not null default uuid_generate_v4(),
    "user_id" uuid not null,
    "item_ids" uuid[] not null,
    "created_at" timestamp with time zone not null default now()
);


alter table "public"."outfit_combinations" enable row level security;

create table "public"."profiles" (
    "id" bigint generated always as identity not null,
    "user_id" uuid,
    "full_name" text,
    "bio" text,
    "profile_picture" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
);


alter table "public"."profiles" enable row level security;

alter table "public"."api_usage" alter column "cost" set data type numeric using "cost"::numeric;

alter table "public"."api_usage" alter column "id" set default uuid_generate_v4();

alter table "public"."api_usage" alter column "timestamp" set not null;

alter table "public"."api_usage" alter column "user_id" set not null;

alter table "public"."clothing_items" drop column "updated_at";

alter table "public"."clothing_items" alter column "category" set not null;

alter table "public"."clothing_items" alter column "created_at" set not null;

alter table "public"."clothing_items" alter column "id" set default uuid_generate_v4();

alter table "public"."clothing_items" alter column "user_id" set not null;

CREATE UNIQUE INDEX api_costs_pkey ON public.api_costs USING btree (id);

CREATE INDEX idx_total_cost ON public.api_costs USING btree (total_cost);

CREATE UNIQUE INDEX outfit_combinations_pkey ON public.outfit_combinations USING btree (id);

CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);

CREATE UNIQUE INDEX unique_user_id ON public.profiles USING btree (user_id);

alter table "public"."api_costs" add constraint "api_costs_pkey" PRIMARY KEY using index "api_costs_pkey";

alter table "public"."outfit_combinations" add constraint "outfit_combinations_pkey" PRIMARY KEY using index "outfit_combinations_pkey";

alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."api_costs" add constraint "api_costs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."api_costs" validate constraint "api_costs_user_id_fkey";

alter table "public"."clothing_items" add constraint "valid_main_group" CHECK ((main_group = ANY (ARRAY['üst giyim'::text, 'alt giyim'::text, 'dış giyim'::text, 'ayakkabı'::text, 'aksesuar'::text]))) not valid;

alter table "public"."clothing_items" validate constraint "valid_main_group";

alter table "public"."outfit_combinations" add constraint "outfit_combinations_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."outfit_combinations" validate constraint "outfit_combinations_user_id_fkey";

alter table "public"."profiles" add constraint "profiles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."profiles" validate constraint "profiles_user_id_fkey";

alter table "public"."profiles" add constraint "unique_user_id" UNIQUE using index "unique_user_id";

alter table "public"."api_usage" add constraint "api_usage_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."api_usage" validate constraint "api_usage_user_id_fkey";

alter table "public"."clothing_items" add constraint "clothing_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."clothing_items" validate constraint "clothing_items_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.count_user_items(user_uid uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
  items_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO items_count 
  FROM clothing_items 
  WHERE user_id = user_uid;
  
  RETURN items_count;
END;
$function$
;

grant delete on table "public"."api_costs" to "anon";

grant insert on table "public"."api_costs" to "anon";

grant references on table "public"."api_costs" to "anon";

grant select on table "public"."api_costs" to "anon";

grant trigger on table "public"."api_costs" to "anon";

grant truncate on table "public"."api_costs" to "anon";

grant update on table "public"."api_costs" to "anon";

grant delete on table "public"."api_costs" to "authenticated";

grant insert on table "public"."api_costs" to "authenticated";

grant references on table "public"."api_costs" to "authenticated";

grant select on table "public"."api_costs" to "authenticated";

grant trigger on table "public"."api_costs" to "authenticated";

grant truncate on table "public"."api_costs" to "authenticated";

grant update on table "public"."api_costs" to "authenticated";

grant delete on table "public"."api_costs" to "service_role";

grant insert on table "public"."api_costs" to "service_role";

grant references on table "public"."api_costs" to "service_role";

grant select on table "public"."api_costs" to "service_role";

grant trigger on table "public"."api_costs" to "service_role";

grant truncate on table "public"."api_costs" to "service_role";

grant update on table "public"."api_costs" to "service_role";

grant delete on table "public"."outfit_combinations" to "anon";

grant insert on table "public"."outfit_combinations" to "anon";

grant references on table "public"."outfit_combinations" to "anon";

grant select on table "public"."outfit_combinations" to "anon";

grant trigger on table "public"."outfit_combinations" to "anon";

grant truncate on table "public"."outfit_combinations" to "anon";

grant update on table "public"."outfit_combinations" to "anon";

grant delete on table "public"."outfit_combinations" to "authenticated";

grant insert on table "public"."outfit_combinations" to "authenticated";

grant references on table "public"."outfit_combinations" to "authenticated";

grant select on table "public"."outfit_combinations" to "authenticated";

grant trigger on table "public"."outfit_combinations" to "authenticated";

grant truncate on table "public"."outfit_combinations" to "authenticated";

grant update on table "public"."outfit_combinations" to "authenticated";

grant delete on table "public"."outfit_combinations" to "service_role";

grant insert on table "public"."outfit_combinations" to "service_role";

grant references on table "public"."outfit_combinations" to "service_role";

grant select on table "public"."outfit_combinations" to "service_role";

grant trigger on table "public"."outfit_combinations" to "service_role";

grant truncate on table "public"."outfit_combinations" to "service_role";

grant update on table "public"."outfit_combinations" to "service_role";

grant delete on table "public"."profiles" to "anon";

grant insert on table "public"."profiles" to "anon";

grant references on table "public"."profiles" to "anon";

grant select on table "public"."profiles" to "anon";

grant trigger on table "public"."profiles" to "anon";

grant truncate on table "public"."profiles" to "anon";

grant update on table "public"."profiles" to "anon";

grant delete on table "public"."profiles" to "authenticated";

grant insert on table "public"."profiles" to "authenticated";

grant references on table "public"."profiles" to "authenticated";

grant select on table "public"."profiles" to "authenticated";

grant trigger on table "public"."profiles" to "authenticated";

grant truncate on table "public"."profiles" to "authenticated";

grant update on table "public"."profiles" to "authenticated";

grant delete on table "public"."profiles" to "service_role";

grant insert on table "public"."profiles" to "service_role";

grant references on table "public"."profiles" to "service_role";

grant select on table "public"."profiles" to "service_role";

grant trigger on table "public"."profiles" to "service_role";

grant truncate on table "public"."profiles" to "service_role";

grant update on table "public"."profiles" to "service_role";

create policy "Users can insert their own API usage"
on "public"."api_usage"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "Users can view their own API usage"
on "public"."api_usage"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "Allow service_role full access"
on "public"."clothing_items"
as permissive
for all
to service_role
using (true)
with check (true);


create policy "Enable delete access for users based on user_id"
on "public"."clothing_items"
as permissive
for delete
to authenticated, service_role
using ((auth.uid() = user_id));


create policy "Enable insert access for authenticated users"
on "public"."clothing_items"
as permissive
for insert
to authenticated, service_role
with check (true);


create policy "Enable insert for authenticated users"
on "public"."clothing_items"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));


create policy "Enable read access for authenticated users"
on "public"."clothing_items"
as permissive
for select
to authenticated, service_role
using (true);


create policy "Enable update access for users based on user_id"
on "public"."clothing_items"
as permissive
for update
to authenticated, service_role
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));


create policy "Users can select own items"
on "public"."clothing_items"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));


create policy "Users can delete their own outfit combinations"
on "public"."outfit_combinations"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "Users can insert their own outfit combinations"
on "public"."outfit_combinations"
as permissive
for insert
to public
with check ((auth.uid() = user_id));


create policy "Users can view their own outfit combinations"
on "public"."outfit_combinations"
as permissive
for select
to public
using ((auth.uid() = user_id));


create policy "Users can delete own items"
on "public"."clothing_items"
as permissive
for delete
to authenticated
using ((auth.uid() = user_id));


create policy "Users can insert own items"
on "public"."clothing_items"
as permissive
for insert
to authenticated
with check ((auth.uid() = user_id));


create policy "Users can update own items"
on "public"."clothing_items"
as permissive
for update
to authenticated
using ((auth.uid() = user_id));


create policy "Users can view own items"
on "public"."clothing_items"
as permissive
for select
to authenticated
using ((auth.uid() = user_id));



