cd C:\Users\czech\Anaconda3\Scripts
call activate cb
call conda install -c SBMLTeam -y python-libsbml
call conda clean -y --all
echo "done"