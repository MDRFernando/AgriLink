export const GEO_DISTRICTS = [
  {
    name: 'Colombo',
    province: 'Western Province',
    dsDivisions: [
      { name: 'Colombo', villages: ['Pettah', 'Slave Island', 'Fort'] },
      { name: 'Homagama', villages: ['Homagama', 'Godagama', 'Kottawa'] },
    ],
  },
  {
    name: 'Gampaha',
    province: 'Western Province',
    dsDivisions: [
      { name: 'Negombo', villages: ['Negombo', 'Katuwapitiya', 'Dalupotha'] },
      { name: 'Minuwangoda', villages: ['Minuwangoda', 'Divulapitiya', 'Kopiwatta'] },
    ],
  },
  {
    name: 'Kandy',
    province: 'Central Province',
    dsDivisions: [
      { name: 'Kandy Four Gravets', villages: ['Kandy', 'Asgiriya', 'Katukele'] },
      { name: 'Udunuwara', villages: ['Gelioya', 'Danture', 'Handessa'] },
    ],
  },
  {
    name: 'Nuwara Eliya',
    province: 'Central Province',
    dsDivisions: [
      { name: 'Nuwara Eliya', villages: ['Nuwara Eliya', 'Hawa Eliya', 'Pedro'] },
      { name: 'Walapane', villages: ['Walapane', 'Nildandahinna', 'Ragala'] },
    ],
  },
  {
    name: 'Galle',
    province: 'Southern Province',
    dsDivisions: [
      { name: 'Galle Four Gravets', villages: ['Galle', 'Kaluwella', 'Magalle'] },
      { name: 'Elpitiya', villages: ['Elpitiya', 'Pitigala', 'Nawadagala'] },
    ],
  },
  {
    name: 'Jaffna',
    province: 'Northern Province',
    dsDivisions: [
      { name: 'Jaffna', villages: ['Jaffna', 'Nallur', 'Chundikuli'] },
      { name: 'Valikamam East', villages: ['Kopay', 'Atchuvely', 'Puttur'] },
    ],
  },
  {
    name: 'Batticaloa',
    province: 'Eastern Province',
    dsDivisions: [
      { name: 'Manmunai North', villages: ['Batticaloa', 'Koddaimunai', 'Tissaveerasingam'] },
      { name: 'Eravur Pattu', villages: ['Chenkalady', 'Vantharumoolai', 'Kommathurai'] },
    ],
  },
  {
    name: 'Kurunegala',
    province: 'North Western Province',
    dsDivisions: [
      { name: 'Kurunegala', villages: ['Kurunegala', 'Malkaduwawa', 'Wehera'] },
      { name: 'Mawathagama', villages: ['Mawathagama', 'Pilessa', 'Wewagedara'] },
      { name: 'Polgahawela', villages: ['Polgahawela', 'Pothuhera', 'Alawwa'] },
    ],
  },
  {
    name: 'Puttalam',
    province: 'North Western Province',
    dsDivisions: [
      { name: 'Puttalam', villages: ['Puttalam', 'Palavi', 'Madampe'] },
      { name: 'Chilaw', villages: ['Chilaw', 'Munneswaram', 'Kakkapalliya'] },
    ],
  },
  {
    name: 'Anuradhapura',
    province: 'North Central Province',
    dsDivisions: [
      { name: 'Nuwaragam Palatha East', villages: ['Anuradhapura', 'Stage I', 'Stage II'] },
      { name: 'Kekirawa', villages: ['Kekirawa', 'Habarana', 'Ganewalpola'] },
    ],
  },
  {
    name: 'Polonnaruwa',
    province: 'North Central Province',
    dsDivisions: [
      { name: 'Thamankaduwa', villages: ['Polonnaruwa', 'Kaduruwela', 'Gallella'] },
      { name: 'Hingurakgoda', villages: ['Hingurakgoda', 'Minneriya', 'Jayanthipura'] },
    ],
  },
  {
    name: 'Badulla',
    province: 'Uva Province',
    dsDivisions: [
      { name: 'Badulla', villages: ['Badulla', 'Hali-Ela', 'Kendagolla'] },
      { name: 'Bandarawela', villages: ['Bandarawela', 'Ettampitiya', 'Makulella'] },
    ],
  },
  {
    name: 'Ratnapura',
    province: 'Sabaragamuwa Province',
    dsDivisions: [
      { name: 'Ratnapura', villages: ['Ratnapura', 'Batugedara', 'Muwagama'] },
      { name: 'Embilipitiya', villages: ['Embilipitiya', 'Udawalawa', 'Panamura'] },
    ],
  },
] as const;

export const TYPICAL_YIELD_KG_PER_ACRE: Record<string, number> = {
  Rice: 2200,
  Wheat: 1500,
  Maize: 1800,
  Potato: 8000,
  Tomato: 12000,
  Onion: 6000,
  Tea: 800,
  Coconut: 3500,
  Chilli: 2500,
  Banana: 8000,
};

export function estimatedYieldKg(
  cropType: string,
  areaAcres: number,
  reported?: number | null,
) {
  if (reported && reported > 0) return reported;
  return areaAcres * (TYPICAL_YIELD_KG_PER_ACRE[cropType] ?? 2000);
}

export function assertValidLocation(input: {
  province: string;
  district: string;
  dsDivision: string;
  village: string;
}) {
  const district = GEO_DISTRICTS.find((d) => d.name === input.district);
  if (!district || district.province !== input.province) {
    return false;
  }
  const ds = district.dsDivisions.find((d) => d.name === input.dsDivision);
  if (!ds) return false;
  return (ds.villages as readonly string[]).includes(input.village);
}
