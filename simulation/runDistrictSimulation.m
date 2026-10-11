function sim=runDistrictSimulation(varargin)
% RUNDISTRICTSImULATION Fast discrete-event approximation of district flow.
%
% Default: 100,000 patients/year, 300/day. Only referable cases are sent
% to remote review. Sweep camera/technician/reviewer counts.

p=inputParser;
addParameter(p,"AnnualPatients",100000);
addParameter(p,"PatientsPerDay",300);
addParameter(p,"DaysPerYear",333);
addParameter(p,"CaptureSec",75);
addParameter(p,"InferenceSec",2.5);
addParameter(p,"NetworkSec",3);
addParameter(p,"ReviewSec",120);
addParameter(p,"ReferralRate",0.20);
parse(p,varargin{:}); o=p.Results;

cameras=1:6; techs=1:8; reviewers=1:8;
rows={};
for c=cameras
 for t=techs
  captureCap=c*3600/o.CaptureSec; %#ok<NASGU>
  edgeCap=c*3600/o.InferenceSec;
  techCap=t*3600/o.CaptureSec;
  daily= min(o.PatientsPerDay, min(captureCap,techCap));
  referred=daily*o.ReferralRate;
  for r=reviewers
      reviewCap=r*3600/o.ReviewSec;
      util=referred/max(reviewCap,eps);
      lambda=referred/max(1,8*3600); % referrals/sec over an 8-h day
      mu=1/o.ReviewSec;
      servers=r;
      % Erlang-C approximation for mean waiting time when stable.
      rho=lambda/(servers*mu);
      if rho<1
          a=lambda/mu;
          sumTerm=sum((a.^(0:servers-1))./factorial(0:servers-1));
          p0=1/(sumTerm + a^servers/(factorial(servers)*(1-rho)));
          pw=(a^servers/(factorial(servers)*(1-rho)))*p0;
          Wq=pw/(servers*mu-lambda);
          qLen=lambda*Wq;
      else
          Wq=Inf; qLen=Inf;
      end
      annual=min(o.AnnualPatients,daily*o.DaysPerYear);
      rows(end+1,:)={c,t,r,daily,annual,util,qLen,Wq/60}; %#ok<AGROW>
  end
 end
end
T=cell2table(rows,"VariableNames", ...
    ["Cameras","Technicians","Reviewers","DailyThroughput", ...
     "AnnualThroughput","ReviewerUtilization","MeanQueue","MeanWaitMin"]);

valid=T.AnnualThroughput>=o.AnnualPatients & T.ReviewerUtilization<0.85;
if any(valid)
    candidates=T(valid,:);
    [~,k]=min(candidates.Cameras+candidates.Technicians+candidates.Reviewers);
    recommendation=candidates(k,:);
else
    recommendation=T(end,:);
end

f=figure("Name","District Screening Bottleneck","Color","w");
scatter3(T.Cameras,T.Reviewers,T.MeanWaitMin,35,T.AnnualThroughput,"filled");
xlabel("Cameras"); ylabel("Reviewers"); zlabel("Mean review wait (min)");
title("District screening resource sweep");
grid on; colorbar;

sim=struct("summary",T,"recommendation",recommendation,"figure",f);
fprintf("\nRecommended feasible resource mix (heuristic):\n");
disp(recommendation);
end
