import zipfile, io, re, glob, os, pandas as pd, numpy as np
files = sorted(glob.glob("data/raw/formd/*_d.zip"))
subs, offs, isss = [], [], []
KEEP_OFF = ['ACCESSIONNUMBER','PREVIOUSACCESSIONNUMBER','INDUSTRYGROUPTYPE','INVESTMENTFUNDTYPE','IS40ACT','REVENUERANGE',
            'FEDERALEXEMPTIONS_ITEMS_LIST','ISAMENDMENT','SALE_DATE','YETTOOCCUR','MORETHANONEYEAR',
            'ISEQUITYTYPE','ISPOOLEDINVESTMENTFUNDTYPE','MINIMUMINVESTMENTACCEPTED','TOTALOFFERINGAMOUNT',
            'TOTALAMOUNTSOLD','TOTALREMAINING','HASNONACCREDITEDINVESTORS','NUMBERNONACCREDITEDINVESTORS',
            'TOTALNUMBERALREADYINVESTED','SALESCOMM_DOLLARAMOUNT','OVER100RECIPIENTFLAG']
KEEP_ISS = ['ACCESSIONNUMBER','IS_PRIMARYISSUER_FLAG','CIK','ENTITYNAME','CITY','STATEORCOUNTRY',
            'JURISDICTIONOFINC','ENTITYTYPE','YEAROFINC_TIMESPAN_CHOICE','YEAROFINC_VALUE_ENTERED']
def rd(z, name, keep):
    for n in z.namelist():
        if n.upper().endswith(name+".TSV"):
            with z.open(n) as fh:
                df = pd.read_csv(fh, sep="\t", dtype=str, low_memory=False, on_bad_lines='skip')
            df.columns = [c.upper() for c in df.columns]
            return df[[c for c in keep if c in df.columns]]
    return None
for f in files:
    q = os.path.basename(f).split("_")[0]
    try:
        with zipfile.ZipFile(f) as z:
            s = rd(z,"FORMDSUBMISSION",['ACCESSIONNUMBER','FILE_NUM','FILING_DATE','SIC_CODE','SUBMISSIONTYPE'])
            o = rd(z,"OFFERING",KEEP_OFF); i = rd(z,"ISSUERS",KEEP_ISS)
        if s is None or o is None or i is None: print("skip(structure)",q); continue
        for d in (s,o,i): d['SRCQ']=q
        subs.append(s); offs.append(o); isss.append(i)
    except Exception as e:
        print("ERR",q,e)
S=pd.concat(subs,ignore_index=True); O=pd.concat(offs,ignore_index=True); I=pd.concat(isss,ignore_index=True)
I=I[I.IS_PRIMARYISSUER_FLAG.str.upper().isin(['YES','Y','TRUE'])]
df = S.merge(O,on=['ACCESSIONNUMBER','SRCQ'],how='inner').merge(I,on=['ACCESSIONNUMBER','SRCQ'],how='left')
def _pdt(s):
    a=pd.to_datetime(s,format='%d-%b-%Y',errors='coerce');b=pd.to_datetime(s,format='%Y-%m-%d %H:%M:%S',errors='coerce');c=pd.to_datetime(s,format='%Y-%m-%d',errors='coerce')
    return a.fillna(b).fillna(c)
df['filing_date']=_pdt(df.FILING_DATE)
df['sale_date']=_pdt(df.SALE_DATE)
for c in ['TOTALOFFERINGAMOUNT','TOTALAMOUNTSOLD','TOTALREMAINING','TOTALNUMBERALREADYINVESTED',
          'MINIMUMINVESTMENTACCEPTED','NUMBERNONACCREDITEDINVESTORS','SALESCOMM_DOLLARAMOUNT']:
    df[c.lower()]=pd.to_numeric(df[c],errors='coerce')
df=df.drop_duplicates(subset=['ACCESSIONNUMBER'])
os.makedirs("data/interim",exist_ok=True)
df.to_parquet("data/interim/formd_all.parquet",index=False)
print("ROWS:",len(df))
print("filing_date range:",df.filing_date.min().date(),"->",df.filing_date.max().date())
print("\nfilings per year:\n",df.groupby(df.filing_date.dt.year).size().to_string())
