// Supabase Edge Function. Deploy with JWT verification disabled, but this function
// validates the opaque token via the database before signing a short-lived photo URL.
import { createClient } from 'npm:@supabase/supabase-js@2';
Deno.serve(async (req: Request) => {
  const cors = {'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'apikey, authorization, content-type','Access-Control-Allow-Methods':'GET, OPTIONS'};
  if(req.method==='OPTIONS')return new Response(null,{headers:cors});
  if(req.method!=='GET')return new Response('Method not allowed',{status:405,headers:cors});
  const token=new URL(req.url).searchParams.get('token');
  if(!token||!/^[0-9a-f-]{36}$/i.test(token))return Response.json({error:'Invalid token'},{status:400,headers:cors});
  const url=Deno.env.get('SUPABASE_URL')!,key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const db=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data,error}=await db.from('students').select('photo_path').eq('token',token).eq('active',true).eq('consent_recorded',true).maybeSingle();
  if(error||!data)return Response.json({error:'Not found'},{status:404,headers:cors});
  if(!data.photo_path)return Response.json({url:null},{headers:cors});
  const signed=await db.storage.from('student-photos').createSignedUrl(data.photo_path,120);
  if(signed.error)return Response.json({error:'Photo unavailable'},{status:500,headers:cors});
  return Response.json({url:signed.data.signedUrl},{headers:{...cors,'Cache-Control':'no-store'}});
});
