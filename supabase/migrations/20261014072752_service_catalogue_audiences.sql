-- Customer-facing catalogue filters; existing category policies still apply.
alter table public.service_categories
  add column audiences text[] not null
  default array['residential','commercial','industrial'];
alter table public.service_categories
  add constraint service_categories_audiences_check check (
    cardinality(audiences) > 0 and
    audiences <@ array['residential','commercial','industrial']::text[]
  );

-- Match the approved FixPK service offering. Never overwrite admin edits.
insert into public.service_categories
  (name,slug,description,icon_name,sort_order,is_published,audiences)
values
 ('Solar Solutions','solar','Residential, commercial & industrial solar systems','solar',10,true,array['residential','commercial','industrial']),
 ('Solar Geysers','solar-geyser','Solar hot water & installation','solar-geyser',20,true,array['residential','commercial']),
 ('CCTV & Security','security','Surveillance & access control','security',30,true,array['residential','commercial','industrial']),
 ('HVAC','hvac','AC installation & maintenance','hvac',40,true,array['residential','commercial','industrial']),
 ('Electrical Services','electrical','Wiring, repairs & installations','electrical',50,true,array['residential','commercial','industrial']),
 ('Facility Maintenance','maintenance','Preventive & corrective care','maintenance',60,true,array['residential','commercial','industrial']),
 ('Plumbing','plumbing','Water systems, leaks & repairs','plumbing',70,true,array['residential','commercial']),
 ('Aluminium & Glass','aluminium','Doors, windows & glass solutions','aluminium',80,true,array['residential','commercial']),
 ('UPVC','upvc','Windows, doors & installation','upvc',90,true,array['residential','commercial']),
 ('Construction & Renovation','construction','Build, renovate & remodel','construction',100,true,array['residential','commercial','industrial']),
 ('Printing Solutions','printing','Signage, branding & design','printing',110,true,array['commercial','industrial']),
 ('Digital Services','digital','Websites, apps & digital marketing','digital',120,true,array['commercial','industrial'])
on conflict (slug) do nothing;

insert into public.services
  (category_id,name,slug,summary,description,sort_order,is_published)
select c.id,v.name,v.slug,v.description,v.description,v.sort_order,true
from (values
 ('solar','Solar Solutions','solar-solutions','Tell us about your property, electricity usage and solar goals. Our team will review the requirements and prepare the next steps.',10),
 ('solar-geyser','Solar Geyser Installation','solar-geyser-installation','Request solar water heating advice, installation or replacement for your property.',20),
 ('security','CCTV & Security Systems','cctv-security-systems','Plan surveillance, access control or a security system upgrade for your home or business.',30),
 ('hvac','HVAC Installation & Maintenance','hvac-installation-maintenance','Request air conditioning installation, servicing, repairs or climate control planning.',40),
 ('electrical','Electrical Installation & Repairs','electrical-installation-repairs','Request electrical wiring, installation, fault diagnosis or repairs.',50),
 ('maintenance','Facility Maintenance','facility-maintenance','Arrange preventive maintenance or corrective repairs for your property and facilities.',60),
 ('plumbing','Plumbing Installation & Repairs','plumbing-installation-repairs','Request plumbing installations, water system repairs or help with leaks.',70),
 ('aluminium','Aluminium & Glass Solutions','aluminium-glass-solutions','Request custom aluminium doors, windows, partitions or glass work.',80),
 ('upvc','UPVC Doors & Windows','upvc-doors-windows','Request UPVC door and window supply, installation or replacement.',90),
 ('construction','Construction & Renovation','construction-renovation','Share your construction, renovation or remodelling project for a tailored quotation.',100),
 ('printing','Printing & Signage','printing-signage','Request business printing, signage, branding materials or design services.',110),
 ('digital','Website Design & Development','website-design-development','Tell us about your website, audience and required features. We design and develop business websites and web applications.',120),
 ('digital','App Development','app-development','Share your mobile app idea, target platforms and features for a development quotation.',121),
 ('digital','Social Media Management','social-media-management','Request content planning, publishing and management for your social media channels.',122),
 ('digital','Ads & Promotion','ads-promotion','Share your audience, goals, channels and budget for a tailored advertising and promotion plan.',123),
 ('digital','Influencer Marketing','influencer-marketing','Request influencer campaign planning and coordination for your brand and target audience.',124)
) as v(category_slug,name,slug,description,sort_order)
join public.service_categories c on c.slug=v.category_slug
on conflict (slug) do nothing;

insert into public.service_questions
  (service_id,question_key,label,help_text,input_type,is_required,sort_order)
select s.id,'requirements','Describe your requirements',
  'Tell us what you need, the project size and any important details.',
  'textarea',true,10
from public.services s
join public.service_categories c on c.id=s.category_id
where c.slug in ('solar','solar-geyser','security','hvac','electrical',
  'maintenance','plumbing','aluminium','upvc','construction','printing','digital')
on conflict (service_id,question_key) do nothing;
